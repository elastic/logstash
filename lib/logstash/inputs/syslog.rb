


<!DOCTYPE html>
<html>
  <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# githubog: http://ogp.me/ns/fb/githubog#">
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>lib/logstash/inputs/syslog.rb at master from logstash/logstash - GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub" />
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub" />
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />

    
    

    <meta content="authenticity_token" name="csrf-param" />
<meta content="ykWfMZd/X6s0wNp0h8Bwm0URMFGcpGIdzt/dWoW35aw=" name="csrf-token" />

    <link href="https://a248.e.akamai.net/assets.github.com/stylesheets/bundles/github-17bd5c725247c06b9269a1fc1ac73dce5567af51.css" media="screen" rel="stylesheet" type="text/css" />
    <link href="https://a248.e.akamai.net/assets.github.com/stylesheets/bundles/github2-32cc2e626eb45a6680961936bb1832e2033ea826.css" media="screen" rel="stylesheet" type="text/css" />
    

    <script src="https://a248.e.akamai.net/assets.github.com/javascripts/bundles/jquery-b2ca07cb3c906ceccfd58811b430b8bc25245926.js" type="text/javascript"></script>
    <script src="https://a248.e.akamai.net/assets.github.com/javascripts/bundles/github-c9288d4ce188cd947980a7f93faccedace72f4d6.js" type="text/javascript"></script>
    

      <link rel='permalink' href='/logstash/logstash/blob/c455a1da340d107dd901d5c95e0403144a137822/lib/logstash/inputs/syslog.rb'>
    <meta property="og:title" content="logstash"/>
    <meta property="og:type" content="githubog:gitrepository"/>
    <meta property="og:url" content="https://github.com/logstash/logstash"/>
    <meta property="og:image" content="https://a248.e.akamai.net/assets.github.com/images/gravatars/gravatar-140.png?1329275960"/>
    <meta property="og:site_name" content="GitHub"/>
    <meta property="og:description" content="logstash - logs/event transport, processing, management, search."/>

    <meta name="description" content="logstash - logs/event transport, processing, management, search." />
  <link href="https://github.com/logstash/logstash/commits/master.atom" rel="alternate" title="Recent Commits to logstash:master" type="application/atom+xml" />

  </head>


  <body class="logged_out page-blob  vis-public env-production " data-blob-contribs-enabled="no">
    


    

      <div id="header" class="true clearfix">
        <div class="container clearfix">
          <a class="site-logo" href="https://github.com">
            <!--[if IE]>
            <img alt="GitHub" class="github-logo" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov7.png?1323882778" />
            <img alt="GitHub" class="github-logo-hover" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov7-hover.png?1324325424" />
            <![endif]-->
            <img alt="GitHub" class="github-logo-4x" height="30" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov7@4x.png?1323882778" />
            <img alt="GitHub" class="github-logo-4x-hover" height="30" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov7@4x-hover.png?1324325424" />
          </a>

                  <!--
      make sure to use fully qualified URLs here since this nav
      is used on error pages on other domains
    -->
    <ul class="top-nav logged_out">
        <li class="pricing"><a href="https://github.com/plans">Signup and Pricing</a></li>
        <li class="explore"><a href="https://github.com/explore">Explore GitHub</a></li>
      <li class="features"><a href="https://github.com/features">Features</a></li>
        <li class="blog"><a href="https://github.com/blog">Blog</a></li>
      <li class="login"><a href="https://github.com/login?return_to=%2Flogstash%2Flogstash%2Fblob%2Fmaster%2Flib%2Flogstash%2Finputs%2Fsyslog.rb">Login</a></li>
    </ul>



          
        </div>
      </div>

      

            <div class="site">
      <div class="container">
        <div class="pagehead repohead instapaper_ignore readability-menu">
        <div class="title-actions-bar">
          <h1 itemscope itemtype="http://data-vocabulary.org/Breadcrumb">
<a href="/logstash" itemprop="url">            <span itemprop="title">logstash</span>
            </a> /
            <strong><a href="/logstash/logstash" class="js-current-repository">logstash</a></strong>
          </h1>
          



              <ul class="pagehead-actions">


          <li><a href="/login?return_to=%2Flogstash%2Flogstash" class="minibutton btn-watch watch-button entice tooltipped leftwards" rel="nofollow" title="You must be logged in to use this feature"><span><span class="icon"></span>Watch</span></a></li>
          <li><a href="/login?return_to=%2Flogstash%2Flogstash" class="minibutton btn-fork fork-button entice tooltipped leftwards" rel="nofollow" title="You must be logged in to use this feature"><span><span class="icon"></span>Fork</span></a></li>


      <li class="repostats">
        <ul class="repo-stats">
          <li class="watchers ">
            <a href="/logstash/logstash/watchers" title="Watchers" class="tooltipped downwards">
              447
            </a>
          </li>
          <li class="forks">
            <a href="/logstash/logstash/network" title="Forks" class="tooltipped downwards">
              88
            </a>
          </li>
        </ul>
      </li>
    </ul>

        </div>

          

  <ul class="tabs">
    <li><a href="/logstash/logstash" class="selected" highlight="repo_sourcerepo_downloadsrepo_commitsrepo_tagsrepo_branches">Code</a></li>
    <li><a href="/logstash/logstash/network" highlight="repo_networkrepo_fork_queue">Network</a>
    <li><a href="/logstash/logstash/pulls" highlight="repo_pulls">Pull Requests <span class='counter'>11</span></a></li>


      <li><a href="/logstash/logstash/wiki" highlight="repo_wiki">Wiki <span class='counter'>10</span></a></li>

    <li><a href="/logstash/logstash/graphs" highlight="repo_graphsrepo_contributors">Stats &amp; Graphs</a></li>

  </ul>

  
<div class="frame frame-center tree-finder" style="display:none"
      data-tree-list-url="/logstash/logstash/tree-list/c455a1da340d107dd901d5c95e0403144a137822"
      data-blob-url-prefix="/logstash/logstash/blob/c455a1da340d107dd901d5c95e0403144a137822"
    >

  <div class="breadcrumb">
    <span class="bold"><a href="/logstash/logstash">logstash</a></span> /
    <input class="tree-finder-input js-navigation-enable" type="text" name="query" autocomplete="off" spellcheck="false">
  </div>

    <div class="octotip">
      <p>
        <a href="/logstash/logstash/dismiss-tree-finder-help" class="dismiss js-dismiss-tree-list-help" title="Hide this notice forever" rel="nofollow">Dismiss</a>
        <span class="bold">Octotip:</span> You've activated the <em>file finder</em>
        by pressing <span class="kbd">t</span> Start typing to filter the
        file list. Use <span class="kbd badmono">↑</span> and
        <span class="kbd badmono">↓</span> to navigate,
        <span class="kbd">enter</span> to view files.
      </p>
    </div>

  <table class="tree-browser" cellpadding="0" cellspacing="0">
    <tr class="js-header"><th>&nbsp;</th><th>name</th></tr>
    <tr class="js-no-results no-results" style="display: none">
      <th colspan="2">No matching files</th>
    </tr>
    <tbody class="js-results-list js-navigation-container">
    </tbody>
  </table>
</div>

<div id="jump-to-line" style="display:none">
  <h2>Jump to Line</h2>
  <form>
    <input class="textfield" type="text">
    <div class="full-button">
      <button type="submit" class="classy">
        <span>Go</span>
      </button>
    </div>
  </form>
</div>


<div class="subnav-bar">

  <ul class="actions subnav">
    <li><a href="/logstash/logstash/tags" class="" highlight="repo_tags">Tags <span class="counter">20</span></a></li>
    <li><a href="/logstash/logstash/downloads" class="blank downloads-blank" highlight="repo_downloads">Downloads <span class="counter">0</span></a></li>
    
  </ul>

  <ul class="scope">
    <li class="switcher">

      <div class="context-menu-container js-menu-container">
        <a href="#"
           class="minibutton bigger switcher js-menu-target js-commitish-button btn-branch repo-tree"
           data-master-branch="master"
           data-ref="master">
          <span><span class="icon"></span><i>branch:</i> master</span>
        </a>

        <div class="context-pane commitish-context js-menu-content">
          <a href="javascript:;" class="close js-menu-close"></a>
          <div class="context-title">Switch Branches/Tags</div>
          <div class="context-body pane-selector commitish-selector js-filterable-commitishes">
            <div class="filterbar">
              <div class="placeholder-field js-placeholder-field">
                <label class="placeholder" for="context-commitish-filter-field" data-placeholder-mode="sticky">Filter branches/tags</label>
                <input type="text" id="context-commitish-filter-field" class="commitish-filter" />
              </div>

              <ul class="tabs">
                <li><a href="#" data-filter="branches" class="selected">Branches</a></li>
                <li><a href="#" data-filter="tags">Tags</a></li>
              </ul>
            </div>

              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/1.0.x/lib/logstash/inputs/syslog.rb" data-name="1.0.x" rel="nofollow">1.0.x</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/feature/zmq/lib/logstash/inputs/syslog.rb" data-name="feature/zmq" rel="nofollow">feature/zmq</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/hack/web-time-zone/lib/logstash/inputs/syslog.rb" data-name="hack/web-time-zone" rel="nofollow">hack/web-time-zone</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/jruby/logstash-web/lib/logstash/inputs/syslog.rb" data-name="jruby/logstash-web" rel="nofollow">jruby/logstash-web</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/LOGSTASH-177/lib/logstash/inputs/syslog.rb" data-name="LOGSTASH-177" rel="nofollow">LOGSTASH-177</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/master/lib/logstash/inputs/syslog.rb" data-name="master" rel="nofollow">master</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/pre-jruby/lib/logstash/inputs/syslog.rb" data-name="pre-jruby" rel="nofollow">pre-jruby</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/profiling/lib/logstash/inputs/syslog.rb" data-name="profiling" rel="nofollow">profiling</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.17/lib/logstash/inputs/syslog.rb" data-name="v1.0.17" rel="nofollow">v1.0.17</a>
                </h4>
              </div>
              <div class="commitish-item branch-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.1.0/lib/logstash/inputs/syslog.rb" data-name="v1.1.0" rel="nofollow">v1.1.0</a>
                </h4>
              </div>

              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.1.0beta9/lib/logstash/inputs/syslog.rb" data-name="v1.1.0beta9" rel="nofollow">v1.1.0beta9</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.1.0beta8/lib/logstash/inputs/syslog.rb" data-name="v1.1.0beta8" rel="nofollow">v1.1.0beta8</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.1.0beta7/lib/logstash/inputs/syslog.rb" data-name="v1.1.0beta7" rel="nofollow">v1.1.0beta7</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.1.0/lib/logstash/inputs/syslog.rb" data-name="v1.1.0" rel="nofollow">v1.1.0</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.17/lib/logstash/inputs/syslog.rb" data-name="v1.0.17" rel="nofollow">v1.0.17</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.16/lib/logstash/inputs/syslog.rb" data-name="v1.0.16" rel="nofollow">v1.0.16</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.15/lib/logstash/inputs/syslog.rb" data-name="v1.0.15" rel="nofollow">v1.0.15</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.14/lib/logstash/inputs/syslog.rb" data-name="v1.0.14" rel="nofollow">v1.0.14</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.12/lib/logstash/inputs/syslog.rb" data-name="v1.0.12" rel="nofollow">v1.0.12</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.11/lib/logstash/inputs/syslog.rb" data-name="v1.0.11" rel="nofollow">v1.0.11</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.10/lib/logstash/inputs/syslog.rb" data-name="v1.0.10" rel="nofollow">v1.0.10</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.9/lib/logstash/inputs/syslog.rb" data-name="v1.0.9" rel="nofollow">v1.0.9</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.7/lib/logstash/inputs/syslog.rb" data-name="v1.0.7" rel="nofollow">v1.0.7</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.6/lib/logstash/inputs/syslog.rb" data-name="v1.0.6" rel="nofollow">v1.0.6</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.5/lib/logstash/inputs/syslog.rb" data-name="v1.0.5" rel="nofollow">v1.0.5</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.4/lib/logstash/inputs/syslog.rb" data-name="v1.0.4" rel="nofollow">v1.0.4</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.1/lib/logstash/inputs/syslog.rb" data-name="v1.0.1" rel="nofollow">v1.0.1</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v1.0.0/lib/logstash/inputs/syslog.rb" data-name="v1.0.0" rel="nofollow">v1.0.0</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/v/lib/logstash/inputs/syslog.rb" data-name="v" rel="nofollow">v</a>
                </h4>
              </div>
              <div class="commitish-item tag-commitish selector-item">
                <h4>
                    <a href="/logstash/logstash/blob/1.0.4/lib/logstash/inputs/syslog.rb" data-name="1.0.4" rel="nofollow">1.0.4</a>
                </h4>
              </div>

            <div class="no-results" style="display:none">Nothing to show</div>
          </div>
        </div><!-- /.commitish-context-context -->
      </div>

    </li>
  </ul>

  <ul class="subnav with-scope">

    <li><a href="/logstash/logstash" class="selected" highlight="repo_source">Files</a></li>
    <li><a href="/logstash/logstash/commits/master" highlight="repo_commits">Commits</a></li>
    <li><a href="/logstash/logstash/branches" class="" highlight="repo_branches" rel="nofollow">Branches <span class="counter">10</span></a></li>
  </ul>

</div>

  
  
  


          

        </div><!-- /.repohead -->

        




    
  <p class="last-commit">Latest commit to the <strong>master</strong> branch</p>

<div class="commit commit-tease js-details-container">
  <p class="commit-title ">
      <a href="/logstash/logstash/commit/c455a1da340d107dd901d5c95e0403144a137822" class="message">we are not ready for such hot rabbits, yet</a>
      
  </p>
  <div class="commit-meta">
    <a href="/logstash/logstash/commit/c455a1da340d107dd901d5c95e0403144a137822" class="sha-block">commit <span class="sha">c455a1da34</span></a>
    <span class="js-clippy clippy-button " data-clipboard-text="c455a1da340d107dd901d5c95e0403144a137822" data-copied-hint="copied!" data-copy-hint="Copy SHA"></span>

    <div class="authorship">
      <img class="gravatar" height="20" src="https://secure.gravatar.com/avatar/fd23fa0562b26f4157a2d7f80095bb07?s=140&amp;d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png" width="20" />
      <span class="author-name"><a href="/fetep">fetep</a></span>
      authored <time class="js-relative-date" datetime="2012-02-22T13:22:00-08:00" title="2012-02-22 13:22:00">February 22, 2012</time>

    </div>
  </div>
</div>


<!-- block_view_fragment_key: views4/v8/blob:v17:815f4cc329ddeb187d138391454f779d -->
  <div id="slider">

    <div class="breadcrumb" data-path="lib/logstash/inputs/syslog.rb/">
      <b itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/logstash/logstash/tree/6e7860d8355d5b1a20e047eadce1e20738247b5c" class="js-rewrite-sha" itemprop="url"><span itemprop="title">logstash</span></a></b> / <span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/logstash/logstash/tree/6e7860d8355d5b1a20e047eadce1e20738247b5c/lib" class="js-rewrite-sha" itemscope="url"><span itemprop="title">lib</span></a></span> / <span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/logstash/logstash/tree/6e7860d8355d5b1a20e047eadce1e20738247b5c/lib/logstash" class="js-rewrite-sha" itemscope="url"><span itemprop="title">logstash</span></a></span> / <span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/logstash/logstash/tree/6e7860d8355d5b1a20e047eadce1e20738247b5c/lib/logstash/inputs" class="js-rewrite-sha" itemscope="url"><span itemprop="title">inputs</span></a></span> / <strong class="final-path">syslog.rb</strong> <span class="js-clippy clippy-button " data-clipboard-text="lib/logstash/inputs/syslog.rb" data-copied-hint="copied!" data-copy-hint="copy to clipboard"></span>
    </div>



    <div class="frames">
      <div class="frame frame-center" data-path="lib/logstash/inputs/syslog.rb/" data-permalink-url="/logstash/logstash/blob/6e7860d8355d5b1a20e047eadce1e20738247b5c/lib/logstash/inputs/syslog.rb" data-title="lib/logstash/inputs/syslog.rb at master from logstash/logstash - GitHub" data-type="blob">

        <div id="files" class="bubble">
          <div class="file">
            <div class="meta">
              <div class="info">
                <span class="icon"><img alt="Txt" height="16" src="https://a248.e.akamai.net/assets.github.com/images/icons/txt.png?1252203928" width="16" /></span>
                <span class="mode" title="File Mode">100644</span>
                  <span>246 lines (212 sloc)</span>
                <span>7.386 kb</span>
              </div>
              <ul class="actions">
                  <li>
                    <a class="file-edit-link minibutton bigger lighter js-rewrite-sha" href="/logstash/logstash/edit/6e7860d8355d5b1a20e047eadce1e20738247b5c/lib/logstash/inputs/syslog.rb" data-method="post" rel="nofollow"><span>Edit this file</span></a>
                  </li>

                <li>
                  <a href="/logstash/logstash/raw/master/lib/logstash/inputs/syslog.rb" class="minibutton btn-raw bigger lighter" id="raw-url"><span><span class="icon"></span>Raw</span></a>
                </li>
                  <li>
                    <a href="/logstash/logstash/blame/master/lib/logstash/inputs/syslog.rb" class="minibutton btn-blame bigger lighter"><span><span class="icon"></span>Blame</span></a>
                  </li>
                <li>
                  <a href="/logstash/logstash/commits/master/lib/logstash/inputs/syslog.rb" class="minibutton btn-history bigger lighter" rel="nofollow"><span><span class="icon"></span>History</span></a>
                </li>
              </ul>
            </div>
              <div class="data type-ruby">
      <table cellpadding="0" cellspacing="0" class="lines">
        <tr>
          <td>
            <pre class="line_numbers"><span id="L1" rel="#L1">1</span>
<span id="L2" rel="#L2">2</span>
<span id="L3" rel="#L3">3</span>
<span id="L4" rel="#L4">4</span>
<span id="L5" rel="#L5">5</span>
<span id="L6" rel="#L6">6</span>
<span id="L7" rel="#L7">7</span>
<span id="L8" rel="#L8">8</span>
<span id="L9" rel="#L9">9</span>
<span id="L10" rel="#L10">10</span>
<span id="L11" rel="#L11">11</span>
<span id="L12" rel="#L12">12</span>
<span id="L13" rel="#L13">13</span>
<span id="L14" rel="#L14">14</span>
<span id="L15" rel="#L15">15</span>
<span id="L16" rel="#L16">16</span>
<span id="L17" rel="#L17">17</span>
<span id="L18" rel="#L18">18</span>
<span id="L19" rel="#L19">19</span>
<span id="L20" rel="#L20">20</span>
<span id="L21" rel="#L21">21</span>
<span id="L22" rel="#L22">22</span>
<span id="L23" rel="#L23">23</span>
<span id="L24" rel="#L24">24</span>
<span id="L25" rel="#L25">25</span>
<span id="L26" rel="#L26">26</span>
<span id="L27" rel="#L27">27</span>
<span id="L28" rel="#L28">28</span>
<span id="L29" rel="#L29">29</span>
<span id="L30" rel="#L30">30</span>
<span id="L31" rel="#L31">31</span>
<span id="L32" rel="#L32">32</span>
<span id="L33" rel="#L33">33</span>
<span id="L34" rel="#L34">34</span>
<span id="L35" rel="#L35">35</span>
<span id="L36" rel="#L36">36</span>
<span id="L37" rel="#L37">37</span>
<span id="L38" rel="#L38">38</span>
<span id="L39" rel="#L39">39</span>
<span id="L40" rel="#L40">40</span>
<span id="L41" rel="#L41">41</span>
<span id="L42" rel="#L42">42</span>
<span id="L43" rel="#L43">43</span>
<span id="L44" rel="#L44">44</span>
<span id="L45" rel="#L45">45</span>
<span id="L46" rel="#L46">46</span>
<span id="L47" rel="#L47">47</span>
<span id="L48" rel="#L48">48</span>
<span id="L49" rel="#L49">49</span>
<span id="L50" rel="#L50">50</span>
<span id="L51" rel="#L51">51</span>
<span id="L52" rel="#L52">52</span>
<span id="L53" rel="#L53">53</span>
<span id="L54" rel="#L54">54</span>
<span id="L55" rel="#L55">55</span>
<span id="L56" rel="#L56">56</span>
<span id="L57" rel="#L57">57</span>
<span id="L58" rel="#L58">58</span>
<span id="L59" rel="#L59">59</span>
<span id="L60" rel="#L60">60</span>
<span id="L61" rel="#L61">61</span>
<span id="L62" rel="#L62">62</span>
<span id="L63" rel="#L63">63</span>
<span id="L64" rel="#L64">64</span>
<span id="L65" rel="#L65">65</span>
<span id="L66" rel="#L66">66</span>
<span id="L67" rel="#L67">67</span>
<span id="L68" rel="#L68">68</span>
<span id="L69" rel="#L69">69</span>
<span id="L70" rel="#L70">70</span>
<span id="L71" rel="#L71">71</span>
<span id="L72" rel="#L72">72</span>
<span id="L73" rel="#L73">73</span>
<span id="L74" rel="#L74">74</span>
<span id="L75" rel="#L75">75</span>
<span id="L76" rel="#L76">76</span>
<span id="L77" rel="#L77">77</span>
<span id="L78" rel="#L78">78</span>
<span id="L79" rel="#L79">79</span>
<span id="L80" rel="#L80">80</span>
<span id="L81" rel="#L81">81</span>
<span id="L82" rel="#L82">82</span>
<span id="L83" rel="#L83">83</span>
<span id="L84" rel="#L84">84</span>
<span id="L85" rel="#L85">85</span>
<span id="L86" rel="#L86">86</span>
<span id="L87" rel="#L87">87</span>
<span id="L88" rel="#L88">88</span>
<span id="L89" rel="#L89">89</span>
<span id="L90" rel="#L90">90</span>
<span id="L91" rel="#L91">91</span>
<span id="L92" rel="#L92">92</span>
<span id="L93" rel="#L93">93</span>
<span id="L94" rel="#L94">94</span>
<span id="L95" rel="#L95">95</span>
<span id="L96" rel="#L96">96</span>
<span id="L97" rel="#L97">97</span>
<span id="L98" rel="#L98">98</span>
<span id="L99" rel="#L99">99</span>
<span id="L100" rel="#L100">100</span>
<span id="L101" rel="#L101">101</span>
<span id="L102" rel="#L102">102</span>
<span id="L103" rel="#L103">103</span>
<span id="L104" rel="#L104">104</span>
<span id="L105" rel="#L105">105</span>
<span id="L106" rel="#L106">106</span>
<span id="L107" rel="#L107">107</span>
<span id="L108" rel="#L108">108</span>
<span id="L109" rel="#L109">109</span>
<span id="L110" rel="#L110">110</span>
<span id="L111" rel="#L111">111</span>
<span id="L112" rel="#L112">112</span>
<span id="L113" rel="#L113">113</span>
<span id="L114" rel="#L114">114</span>
<span id="L115" rel="#L115">115</span>
<span id="L116" rel="#L116">116</span>
<span id="L117" rel="#L117">117</span>
<span id="L118" rel="#L118">118</span>
<span id="L119" rel="#L119">119</span>
<span id="L120" rel="#L120">120</span>
<span id="L121" rel="#L121">121</span>
<span id="L122" rel="#L122">122</span>
<span id="L123" rel="#L123">123</span>
<span id="L124" rel="#L124">124</span>
<span id="L125" rel="#L125">125</span>
<span id="L126" rel="#L126">126</span>
<span id="L127" rel="#L127">127</span>
<span id="L128" rel="#L128">128</span>
<span id="L129" rel="#L129">129</span>
<span id="L130" rel="#L130">130</span>
<span id="L131" rel="#L131">131</span>
<span id="L132" rel="#L132">132</span>
<span id="L133" rel="#L133">133</span>
<span id="L134" rel="#L134">134</span>
<span id="L135" rel="#L135">135</span>
<span id="L136" rel="#L136">136</span>
<span id="L137" rel="#L137">137</span>
<span id="L138" rel="#L138">138</span>
<span id="L139" rel="#L139">139</span>
<span id="L140" rel="#L140">140</span>
<span id="L141" rel="#L141">141</span>
<span id="L142" rel="#L142">142</span>
<span id="L143" rel="#L143">143</span>
<span id="L144" rel="#L144">144</span>
<span id="L145" rel="#L145">145</span>
<span id="L146" rel="#L146">146</span>
<span id="L147" rel="#L147">147</span>
<span id="L148" rel="#L148">148</span>
<span id="L149" rel="#L149">149</span>
<span id="L150" rel="#L150">150</span>
<span id="L151" rel="#L151">151</span>
<span id="L152" rel="#L152">152</span>
<span id="L153" rel="#L153">153</span>
<span id="L154" rel="#L154">154</span>
<span id="L155" rel="#L155">155</span>
<span id="L156" rel="#L156">156</span>
<span id="L157" rel="#L157">157</span>
<span id="L158" rel="#L158">158</span>
<span id="L159" rel="#L159">159</span>
<span id="L160" rel="#L160">160</span>
<span id="L161" rel="#L161">161</span>
<span id="L162" rel="#L162">162</span>
<span id="L163" rel="#L163">163</span>
<span id="L164" rel="#L164">164</span>
<span id="L165" rel="#L165">165</span>
<span id="L166" rel="#L166">166</span>
<span id="L167" rel="#L167">167</span>
<span id="L168" rel="#L168">168</span>
<span id="L169" rel="#L169">169</span>
<span id="L170" rel="#L170">170</span>
<span id="L171" rel="#L171">171</span>
<span id="L172" rel="#L172">172</span>
<span id="L173" rel="#L173">173</span>
<span id="L174" rel="#L174">174</span>
<span id="L175" rel="#L175">175</span>
<span id="L176" rel="#L176">176</span>
<span id="L177" rel="#L177">177</span>
<span id="L178" rel="#L178">178</span>
<span id="L179" rel="#L179">179</span>
<span id="L180" rel="#L180">180</span>
<span id="L181" rel="#L181">181</span>
<span id="L182" rel="#L182">182</span>
<span id="L183" rel="#L183">183</span>
<span id="L184" rel="#L184">184</span>
<span id="L185" rel="#L185">185</span>
<span id="L186" rel="#L186">186</span>
<span id="L187" rel="#L187">187</span>
<span id="L188" rel="#L188">188</span>
<span id="L189" rel="#L189">189</span>
<span id="L190" rel="#L190">190</span>
<span id="L191" rel="#L191">191</span>
<span id="L192" rel="#L192">192</span>
<span id="L193" rel="#L193">193</span>
<span id="L194" rel="#L194">194</span>
<span id="L195" rel="#L195">195</span>
<span id="L196" rel="#L196">196</span>
<span id="L197" rel="#L197">197</span>
<span id="L198" rel="#L198">198</span>
<span id="L199" rel="#L199">199</span>
<span id="L200" rel="#L200">200</span>
<span id="L201" rel="#L201">201</span>
<span id="L202" rel="#L202">202</span>
<span id="L203" rel="#L203">203</span>
<span id="L204" rel="#L204">204</span>
<span id="L205" rel="#L205">205</span>
<span id="L206" rel="#L206">206</span>
<span id="L207" rel="#L207">207</span>
<span id="L208" rel="#L208">208</span>
<span id="L209" rel="#L209">209</span>
<span id="L210" rel="#L210">210</span>
<span id="L211" rel="#L211">211</span>
<span id="L212" rel="#L212">212</span>
<span id="L213" rel="#L213">213</span>
<span id="L214" rel="#L214">214</span>
<span id="L215" rel="#L215">215</span>
<span id="L216" rel="#L216">216</span>
<span id="L217" rel="#L217">217</span>
<span id="L218" rel="#L218">218</span>
<span id="L219" rel="#L219">219</span>
<span id="L220" rel="#L220">220</span>
<span id="L221" rel="#L221">221</span>
<span id="L222" rel="#L222">222</span>
<span id="L223" rel="#L223">223</span>
<span id="L224" rel="#L224">224</span>
<span id="L225" rel="#L225">225</span>
<span id="L226" rel="#L226">226</span>
<span id="L227" rel="#L227">227</span>
<span id="L228" rel="#L228">228</span>
<span id="L229" rel="#L229">229</span>
<span id="L230" rel="#L230">230</span>
<span id="L231" rel="#L231">231</span>
<span id="L232" rel="#L232">232</span>
<span id="L233" rel="#L233">233</span>
<span id="L234" rel="#L234">234</span>
<span id="L235" rel="#L235">235</span>
<span id="L236" rel="#L236">236</span>
<span id="L237" rel="#L237">237</span>
<span id="L238" rel="#L238">238</span>
<span id="L239" rel="#L239">239</span>
<span id="L240" rel="#L240">240</span>
<span id="L241" rel="#L241">241</span>
<span id="L242" rel="#L242">242</span>
<span id="L243" rel="#L243">243</span>
<span id="L244" rel="#L244">244</span>
<span id="L245" rel="#L245">245</span>
</pre>
          </td>
          <td width="100%">
                <div class="highlight"><pre><div class='line' id='LC1'><span class="nb">require</span> <span class="s2">&quot;date&quot;</span></div><div class='line' id='LC2'><span class="nb">require</span> <span class="s2">&quot;logstash/filters/grok&quot;</span></div><div class='line' id='LC3'><span class="nb">require</span> <span class="s2">&quot;logstash/filters/date&quot;</span></div><div class='line' id='LC4'><span class="nb">require</span> <span class="s2">&quot;logstash/inputs/base&quot;</span></div><div class='line' id='LC5'><span class="nb">require</span> <span class="s2">&quot;logstash/namespace&quot;</span></div><div class='line' id='LC6'><span class="nb">require</span> <span class="s2">&quot;socket&quot;</span></div><div class='line' id='LC7'><br/></div><div class='line' id='LC8'><span class="c1"># Read syslog messages as events over the network.</span></div><div class='line' id='LC9'><span class="c1">#</span></div><div class='line' id='LC10'><span class="c1"># This input is a good choice if you already use syslog today.</span></div><div class='line' id='LC11'><span class="c1"># It is also a good choice if you want to receive logs from</span></div><div class='line' id='LC12'><span class="c1"># appliances and network devices where you cannot run your own</span></div><div class='line' id='LC13'><span class="c1"># log collector.</span></div><div class='line' id='LC14'><span class="c1">#</span></div><div class='line' id='LC15'><span class="c1"># Of course, &#39;syslog&#39; is a very muddy term. This input only supports RFC3164</span></div><div class='line' id='LC16'><span class="c1"># syslog with some small modifications. The date format is allowed to be</span></div><div class='line' id='LC17'><span class="c1"># RFC3164 style or ISO8601. Otherwise the rest of the RFC3164 must be obeyed.</span></div><div class='line' id='LC18'><span class="c1"># If you do not use RFC3164, do not use this input.</span></div><div class='line' id='LC19'><span class="c1">#</span></div><div class='line' id='LC20'><span class="c1"># Note: this input will start listeners on both TCP and UDP</span></div><div class='line' id='LC21'><span class="k">class</span> <span class="nc">LogStash</span><span class="o">::</span><span class="no">Inputs</span><span class="o">::</span><span class="no">Syslog</span> <span class="o">&lt;</span> <span class="no">LogStash</span><span class="o">::</span><span class="no">Inputs</span><span class="o">::</span><span class="no">Base</span></div><div class='line' id='LC22'>&nbsp;&nbsp;<span class="n">config_name</span> <span class="s2">&quot;syslog&quot;</span></div><div class='line' id='LC23'>&nbsp;&nbsp;<span class="n">plugin_status</span> <span class="s2">&quot;experimental&quot;</span></div><div class='line' id='LC24'><br/></div><div class='line' id='LC25'>&nbsp;&nbsp;<span class="c1"># The address to listen on</span></div><div class='line' id='LC26'>&nbsp;&nbsp;<span class="n">config</span> <span class="ss">:host</span><span class="p">,</span> <span class="ss">:validate</span> <span class="o">=&gt;</span> <span class="ss">:string</span><span class="p">,</span> <span class="ss">:default</span> <span class="o">=&gt;</span> <span class="s2">&quot;0.0.0.0&quot;</span></div><div class='line' id='LC27'><br/></div><div class='line' id='LC28'>&nbsp;&nbsp;<span class="c1"># The port to listen on. Remember that ports less than 1024 (privileged</span></div><div class='line' id='LC29'>&nbsp;&nbsp;<span class="c1"># ports) may require root to use.</span></div><div class='line' id='LC30'>&nbsp;&nbsp;<span class="n">config</span> <span class="ss">:port</span><span class="p">,</span> <span class="ss">:validate</span> <span class="o">=&gt;</span> <span class="ss">:number</span><span class="p">,</span> <span class="ss">:default</span> <span class="o">=&gt;</span> <span class="mi">514</span></div><div class='line' id='LC31'><br/></div><div class='line' id='LC32'>&nbsp;&nbsp;<span class="c1"># Use label parsing for severity and facility levels</span></div><div class='line' id='LC33'>&nbsp;&nbsp;<span class="n">config</span> <span class="ss">:use_labels</span><span class="p">,</span> <span class="ss">:validate</span> <span class="o">=&gt;</span> <span class="ss">:boolean</span><span class="p">,</span> <span class="ss">:default</span> <span class="o">=&gt;</span> <span class="kp">true</span></div><div class='line' id='LC34'><br/></div><div class='line' id='LC35'>&nbsp;&nbsp;<span class="c1"># Labels for facility levels</span></div><div class='line' id='LC36'>&nbsp;&nbsp;<span class="c1"># This comes from RFC3164.</span></div><div class='line' id='LC37'>&nbsp;&nbsp;<span class="n">config</span> <span class="ss">:facility_labels</span><span class="p">,</span> <span class="ss">:validate</span> <span class="o">=&gt;</span> <span class="ss">:array</span><span class="p">,</span> <span class="ss">:default</span> <span class="o">=&gt;</span> <span class="o">[</span> <span class="s2">&quot;kernel&quot;</span><span class="p">,</span> <span class="s2">&quot;user-level&quot;</span><span class="p">,</span> <span class="s2">&quot;mail&quot;</span><span class="p">,</span> <span class="s2">&quot;system&quot;</span><span class="p">,</span> <span class="s2">&quot;security/authorization&quot;</span><span class="p">,</span> <span class="s2">&quot;syslogd&quot;</span><span class="p">,</span> <span class="s2">&quot;line printer&quot;</span><span class="p">,</span> <span class="s2">&quot;network news&quot;</span><span class="p">,</span> <span class="s2">&quot;UUCP&quot;</span><span class="p">,</span> <span class="s2">&quot;clock&quot;</span><span class="p">,</span> <span class="s2">&quot;security/authorization&quot;</span><span class="p">,</span> <span class="s2">&quot;FTP&quot;</span><span class="p">,</span> <span class="s2">&quot;NTP&quot;</span><span class="p">,</span> <span class="s2">&quot;log audit&quot;</span><span class="p">,</span> <span class="s2">&quot;log alert&quot;</span><span class="p">,</span> <span class="s2">&quot;clock&quot;</span><span class="p">,</span> <span class="s2">&quot;local0&quot;</span><span class="p">,</span> <span class="s2">&quot;local1&quot;</span><span class="p">,</span> <span class="s2">&quot;local2&quot;</span><span class="p">,</span> <span class="s2">&quot;local3&quot;</span><span class="p">,</span> <span class="s2">&quot;local4&quot;</span><span class="p">,</span> <span class="s2">&quot;local5&quot;</span><span class="p">,</span> <span class="s2">&quot;local6&quot;</span><span class="p">,</span> <span class="s2">&quot;local7&quot;</span> <span class="o">]</span></div><div class='line' id='LC38'><br/></div><div class='line' id='LC39'>&nbsp;&nbsp;<span class="c1"># Labels for severity levels</span></div><div class='line' id='LC40'>&nbsp;&nbsp;<span class="c1"># This comes from RFC3164.</span></div><div class='line' id='LC41'>&nbsp;&nbsp;<span class="n">config</span> <span class="ss">:severity_labels</span><span class="p">,</span> <span class="ss">:validate</span> <span class="o">=&gt;</span> <span class="ss">:array</span><span class="p">,</span> <span class="ss">:default</span> <span class="o">=&gt;</span> <span class="o">[</span> <span class="s2">&quot;Emergency&quot;</span> <span class="p">,</span> <span class="s2">&quot;Alert&quot;</span><span class="p">,</span> <span class="s2">&quot;Critical&quot;</span><span class="p">,</span> <span class="s2">&quot;Error&quot;</span><span class="p">,</span> <span class="s2">&quot;Warning&quot;</span><span class="p">,</span> <span class="s2">&quot;Notice&quot;</span><span class="p">,</span> <span class="s2">&quot;Informational&quot;</span><span class="p">,</span> <span class="s2">&quot;Debug&quot;</span> <span class="o">]</span></div><div class='line' id='LC42'><br/></div><div class='line' id='LC43'>&nbsp;&nbsp;<span class="kp">public</span></div><div class='line' id='LC44'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">initialize</span><span class="p">(</span><span class="n">params</span><span class="p">)</span></div><div class='line' id='LC45'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">super</span></div><div class='line' id='LC46'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@shutdown_requested</span> <span class="o">=</span> <span class="kp">false</span></div><div class='line' id='LC47'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">BasicSocket</span><span class="o">.</span><span class="n">do_not_reverse_lookup</span> <span class="o">=</span> <span class="kp">true</span></div><div class='line' id='LC48'><br/></div><div class='line' id='LC49'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># force &quot;plain&quot; format. others don&#39;t make sense here.</span></div><div class='line' id='LC50'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@format</span> <span class="o">=</span> <span class="s2">&quot;plain&quot;</span></div><div class='line' id='LC51'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def initialize</span></div><div class='line' id='LC52'><br/></div><div class='line' id='LC53'>&nbsp;&nbsp;<span class="kp">public</span></div><div class='line' id='LC54'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">register</span></div><div class='line' id='LC55'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">warn</span><span class="p">(</span><span class="s2">&quot;ATTENTION: THIS PLUGIN WILL BE REMOVED IN LOGSTASH 1.2.0&quot;</span><span class="p">)</span></div><div class='line' id='LC56'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@grok_filter</span> <span class="o">=</span> <span class="no">LogStash</span><span class="o">::</span><span class="no">Filters</span><span class="o">::</span><span class="no">Grok</span><span class="o">.</span><span class="n">new</span><span class="p">({</span></div><div class='line' id='LC57'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;type&quot;</span>    <span class="o">=&gt;</span> <span class="o">[</span><span class="vi">@config</span><span class="o">[</span><span class="s2">&quot;type&quot;</span><span class="o">]]</span><span class="p">,</span></div><div class='line' id='LC58'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;pattern&quot;</span> <span class="o">=&gt;</span> <span class="o">[</span><span class="s2">&quot;&lt;%{POSINT:priority}&gt;%{SYSLOGLINE}&quot;</span><span class="o">]</span><span class="p">,</span></div><div class='line' id='LC59'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">})</span></div><div class='line' id='LC60'><br/></div><div class='line' id='LC61'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@date_filter</span> <span class="o">=</span> <span class="no">LogStash</span><span class="o">::</span><span class="no">Filters</span><span class="o">::</span><span class="no">Date</span><span class="o">.</span><span class="n">new</span><span class="p">({</span></div><div class='line' id='LC62'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;type&quot;</span>          <span class="o">=&gt;</span> <span class="o">[</span><span class="vi">@config</span><span class="o">[</span><span class="s2">&quot;type&quot;</span><span class="o">]]</span><span class="p">,</span></div><div class='line' id='LC63'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;timestamp&quot;</span>     <span class="o">=&gt;</span> <span class="o">[</span><span class="s2">&quot;MMM  d HH:mm:ss&quot;</span><span class="p">,</span> <span class="s2">&quot;MMM dd HH:mm:ss&quot;</span><span class="o">]</span><span class="p">,</span></div><div class='line' id='LC64'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="s2">&quot;timestamp8601&quot;</span> <span class="o">=&gt;</span> <span class="o">[</span><span class="s2">&quot;ISO8601&quot;</span><span class="o">]</span><span class="p">,</span></div><div class='line' id='LC65'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="p">})</span></div><div class='line' id='LC66'><br/></div><div class='line' id='LC67'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@grok_filter</span><span class="o">.</span><span class="n">register</span></div><div class='line' id='LC68'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@date_filter</span><span class="o">.</span><span class="n">register</span></div><div class='line' id='LC69'><br/></div><div class='line' id='LC70'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp_clients</span> <span class="o">=</span> <span class="o">[]</span></div><div class='line' id='LC71'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def register</span></div><div class='line' id='LC72'><br/></div><div class='line' id='LC73'>&nbsp;&nbsp;<span class="kp">public</span></div><div class='line' id='LC74'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="n">output_queue</span><span class="p">)</span></div><div class='line' id='LC75'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># udp server</span></div><div class='line' id='LC76'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">Thread</span><span class="o">.</span><span class="n">new</span> <span class="k">do</span></div><div class='line' id='LC77'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">LogStash</span><span class="o">::</span><span class="no">Util</span><span class="o">::</span><span class="n">set_thread_name</span><span class="p">(</span><span class="s2">&quot;input|syslog|udp&quot;</span><span class="p">)</span></div><div class='line' id='LC78'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">begin</span></div><div class='line' id='LC79'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">udp_listener</span><span class="p">(</span><span class="n">output_queue</span><span class="p">)</span></div><div class='line' id='LC80'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">rescue</span> <span class="o">=&gt;</span> <span class="n">e</span></div><div class='line' id='LC81'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">break</span> <span class="k">if</span> <span class="vi">@shutdown_requested</span></div><div class='line' id='LC82'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">warn</span><span class="p">(</span><span class="s2">&quot;syslog udp listener died&quot;</span><span class="p">,</span></div><div class='line' id='LC83'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="ss">:address</span> <span class="o">=&gt;</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="vi">@host</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="vi">@port</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">,</span> <span class="ss">:exception</span> <span class="o">=&gt;</span> <span class="n">e</span><span class="p">,</span></div><div class='line' id='LC84'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="ss">:backtrace</span> <span class="o">=&gt;</span> <span class="n">e</span><span class="o">.</span><span class="n">backtrace</span><span class="p">)</span></div><div class='line' id='LC85'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">sleep</span><span class="p">(</span><span class="mi">5</span><span class="p">)</span></div><div class='line' id='LC86'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">retry</span></div><div class='line' id='LC87'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># begin</span></div><div class='line' id='LC88'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># Thread.new</span></div><div class='line' id='LC89'><br/></div><div class='line' id='LC90'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># tcp server</span></div><div class='line' id='LC91'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">Thread</span><span class="o">.</span><span class="n">new</span> <span class="k">do</span></div><div class='line' id='LC92'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">LogStash</span><span class="o">::</span><span class="no">Util</span><span class="o">::</span><span class="n">set_thread_name</span><span class="p">(</span><span class="s2">&quot;input|syslog|tcp&quot;</span><span class="p">)</span></div><div class='line' id='LC93'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">begin</span></div><div class='line' id='LC94'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">tcp_listener</span><span class="p">(</span><span class="n">output_queue</span><span class="p">)</span></div><div class='line' id='LC95'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">rescue</span> <span class="o">=&gt;</span> <span class="n">e</span></div><div class='line' id='LC96'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">break</span> <span class="k">if</span> <span class="vi">@shutdown_requested</span></div><div class='line' id='LC97'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">warn</span><span class="p">(</span><span class="s2">&quot;syslog tcp listener died&quot;</span><span class="p">,</span></div><div class='line' id='LC98'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="ss">:address</span> <span class="o">=&gt;</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="vi">@host</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="vi">@port</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">,</span> <span class="ss">:exception</span> <span class="o">=&gt;</span> <span class="n">e</span><span class="p">,</span></div><div class='line' id='LC99'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="ss">:backtrace</span> <span class="o">=&gt;</span> <span class="n">e</span><span class="o">.</span><span class="n">backtrace</span><span class="p">)</span></div><div class='line' id='LC100'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="nb">sleep</span><span class="p">(</span><span class="mi">5</span><span class="p">)</span></div><div class='line' id='LC101'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">retry</span></div><div class='line' id='LC102'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># begin</span></div><div class='line' id='LC103'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># Thread.new</span></div><div class='line' id='LC104'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def run</span></div><div class='line' id='LC105'><br/></div><div class='line' id='LC106'>&nbsp;&nbsp;<span class="kp">private</span></div><div class='line' id='LC107'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">udp_listener</span><span class="p">(</span><span class="n">output_queue</span><span class="p">)</span></div><div class='line' id='LC108'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="s2">&quot;Starting syslog udp listener&quot;</span><span class="p">,</span> <span class="ss">:address</span> <span class="o">=&gt;</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="vi">@host</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="vi">@port</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">)</span></div><div class='line' id='LC109'><br/></div><div class='line' id='LC110'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="vi">@udp</span></div><div class='line' id='LC111'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span><span class="o">.</span><span class="n">close_read</span></div><div class='line' id='LC112'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span><span class="o">.</span><span class="n">close_write</span></div><div class='line' id='LC113'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC114'><br/></div><div class='line' id='LC115'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span> <span class="o">=</span> <span class="no">UDPSocket</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="no">Socket</span><span class="o">::</span><span class="no">AF_INET</span><span class="p">)</span></div><div class='line' id='LC116'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span><span class="o">.</span><span class="n">bind</span><span class="p">(</span><span class="vi">@host</span><span class="p">,</span> <span class="vi">@port</span><span class="p">)</span></div><div class='line' id='LC117'><br/></div><div class='line' id='LC118'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="kp">loop</span> <span class="k">do</span></div><div class='line' id='LC119'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">line</span><span class="p">,</span> <span class="n">client</span> <span class="o">=</span> <span class="vi">@udp</span><span class="o">.</span><span class="n">recvfrom</span><span class="p">(</span><span class="mi">9000</span><span class="p">)</span></div><div class='line' id='LC120'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># Ruby uri sucks, so don&#39;t use it.</span></div><div class='line' id='LC121'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">source</span> <span class="o">=</span> <span class="s2">&quot;syslog://</span><span class="si">#{</span><span class="n">client</span><span class="o">[</span><span class="mi">3</span><span class="o">]</span><span class="si">}</span><span class="s2">/&quot;</span></div><div class='line' id='LC122'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">e</span> <span class="o">=</span> <span class="n">to_event</span><span class="p">(</span><span class="n">line</span><span class="o">.</span><span class="n">chomp</span><span class="p">,</span> <span class="n">source</span><span class="p">)</span></div><div class='line' id='LC123'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="n">e</span></div><div class='line' id='LC124'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">syslog_relay</span><span class="p">(</span><span class="n">e</span><span class="p">,</span> <span class="n">source</span><span class="p">)</span></div><div class='line' id='LC125'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">output_queue</span> <span class="o">&lt;&lt;</span> <span class="n">e</span></div><div class='line' id='LC126'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC127'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC128'>&nbsp;&nbsp;<span class="k">ensure</span></div><div class='line' id='LC129'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">close_udp</span></div><div class='line' id='LC130'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def udp_listener</span></div><div class='line' id='LC131'><br/></div><div class='line' id='LC132'>&nbsp;&nbsp;<span class="kp">private</span></div><div class='line' id='LC133'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">tcp_listener</span><span class="p">(</span><span class="n">output_queue</span><span class="p">)</span></div><div class='line' id='LC134'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="s2">&quot;Starting syslog tcp listener&quot;</span><span class="p">,</span> <span class="ss">:address</span> <span class="o">=&gt;</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="vi">@host</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="vi">@port</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">)</span></div><div class='line' id='LC135'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp</span> <span class="o">=</span> <span class="no">TCPServer</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="vi">@host</span><span class="p">,</span> <span class="vi">@port</span><span class="p">)</span></div><div class='line' id='LC136'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp_clients</span> <span class="o">=</span> <span class="o">[]</span></div><div class='line' id='LC137'><br/></div><div class='line' id='LC138'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="kp">loop</span> <span class="k">do</span></div><div class='line' id='LC139'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">client</span> <span class="o">=</span> <span class="vi">@tcp</span><span class="o">.</span><span class="n">accept</span></div><div class='line' id='LC140'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp_clients</span> <span class="o">&lt;&lt;</span> <span class="n">client</span></div><div class='line' id='LC141'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">Thread</span><span class="o">.</span><span class="n">new</span><span class="p">(</span><span class="n">client</span><span class="p">)</span> <span class="k">do</span> <span class="o">|</span><span class="n">client</span><span class="o">|</span></div><div class='line' id='LC142'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">ip</span><span class="p">,</span> <span class="n">port</span> <span class="o">=</span> <span class="n">client</span><span class="o">.</span><span class="n">peeraddr</span><span class="o">[</span><span class="mi">3</span><span class="o">]</span><span class="p">,</span> <span class="n">client</span><span class="o">.</span><span class="n">peeraddr</span><span class="o">[</span><span class="mi">1</span><span class="o">]</span></div><div class='line' id='LC143'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="s2">&quot;new connection&quot;</span><span class="p">,</span> <span class="ss">:client</span> <span class="o">=&gt;</span> <span class="s2">&quot;</span><span class="si">#{</span><span class="n">ip</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="n">port</span><span class="si">}</span><span class="s2">&quot;</span><span class="p">)</span></div><div class='line' id='LC144'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="no">LogStash</span><span class="o">::</span><span class="no">Util</span><span class="o">::</span><span class="n">set_thread_name</span><span class="p">(</span><span class="s2">&quot;input|syslog|tcp|</span><span class="si">#{</span><span class="n">ip</span><span class="si">}</span><span class="s2">:</span><span class="si">#{</span><span class="n">port</span><span class="si">}</span><span class="s2">}&quot;</span><span class="p">)</span></div><div class='line' id='LC145'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="n">ip</span><span class="o">.</span><span class="n">include?</span><span class="p">(</span><span class="s2">&quot;:&quot;</span><span class="p">)</span> <span class="c1"># ipv6</span></div><div class='line' id='LC146'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">source</span> <span class="o">=</span> <span class="s2">&quot;syslog://[</span><span class="si">#{</span><span class="n">ip</span><span class="si">}</span><span class="s2">]/&quot;</span></div><div class='line' id='LC147'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC148'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">source</span> <span class="o">=</span> <span class="s2">&quot;syslog://</span><span class="si">#{</span><span class="n">ip</span><span class="si">}</span><span class="s2">/&quot;</span></div><div class='line' id='LC149'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC150'><br/></div><div class='line' id='LC151'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">begin</span></div><div class='line' id='LC152'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">client</span><span class="o">.</span><span class="n">each</span> <span class="k">do</span> <span class="o">|</span><span class="n">line</span><span class="o">|</span></div><div class='line' id='LC153'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">e</span> <span class="o">=</span> <span class="n">to_event</span><span class="p">(</span><span class="n">line</span><span class="o">.</span><span class="n">chomp</span><span class="p">,</span> <span class="n">source</span><span class="p">)</span></div><div class='line' id='LC154'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="n">e</span></div><div class='line' id='LC155'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">syslog_relay</span><span class="p">(</span><span class="n">e</span><span class="p">,</span> <span class="n">source</span><span class="p">)</span></div><div class='line' id='LC156'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">output_queue</span> <span class="o">&lt;&lt;</span> <span class="n">e</span></div><div class='line' id='LC157'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># e</span></div><div class='line' id='LC158'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># client.each</span></div><div class='line' id='LC159'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">rescue</span> <span class="no">Errno</span><span class="o">::</span><span class="no">ECONNRESET</span></div><div class='line' id='LC160'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC161'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># Thread.new</span></div><div class='line' id='LC162'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># loop do</span></div><div class='line' id='LC163'>&nbsp;&nbsp;<span class="k">ensure</span></div><div class='line' id='LC164'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">close_tcp</span></div><div class='line' id='LC165'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def tcp_listener</span></div><div class='line' id='LC166'><br/></div><div class='line' id='LC167'>&nbsp;&nbsp;<span class="kp">public</span></div><div class='line' id='LC168'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">teardown</span></div><div class='line' id='LC169'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@shutdown_requested</span> <span class="o">=</span> <span class="kp">true</span></div><div class='line' id='LC170'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">close_udp</span></div><div class='line' id='LC171'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">close_tcp</span></div><div class='line' id='LC172'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">finished</span></div><div class='line' id='LC173'>&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC174'><br/></div><div class='line' id='LC175'>&nbsp;&nbsp;<span class="kp">private</span></div><div class='line' id='LC176'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">close_udp</span></div><div class='line' id='LC177'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="vi">@udp</span></div><div class='line' id='LC178'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span><span class="o">.</span><span class="n">close_read</span> <span class="k">rescue</span> <span class="kp">nil</span></div><div class='line' id='LC179'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span><span class="o">.</span><span class="n">close_write</span> <span class="k">rescue</span> <span class="kp">nil</span></div><div class='line' id='LC180'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC181'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@udp</span> <span class="o">=</span> <span class="kp">nil</span></div><div class='line' id='LC182'>&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC183'><br/></div><div class='line' id='LC184'>&nbsp;&nbsp;<span class="kp">private</span></div><div class='line' id='LC185'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">close_tcp</span></div><div class='line' id='LC186'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># If we somehow have this left open, close it.</span></div><div class='line' id='LC187'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp_clients</span><span class="o">.</span><span class="n">each</span> <span class="k">do</span> <span class="o">|</span><span class="n">client</span><span class="o">|</span></div><div class='line' id='LC188'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">client</span><span class="o">.</span><span class="n">close</span> <span class="k">rescue</span> <span class="kp">nil</span></div><div class='line' id='LC189'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC190'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp</span><span class="o">.</span><span class="n">close</span> <span class="k">if</span> <span class="vi">@tcp</span> <span class="k">rescue</span> <span class="kp">nil</span></div><div class='line' id='LC191'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@tcp</span> <span class="o">=</span> <span class="kp">nil</span></div><div class='line' id='LC192'>&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC193'><br/></div><div class='line' id='LC194'>&nbsp;&nbsp;<span class="c1"># Following RFC3164 where sane, we&#39;ll try to parse a received message</span></div><div class='line' id='LC195'>&nbsp;&nbsp;<span class="c1"># as if you were relaying a syslog message to it.</span></div><div class='line' id='LC196'>&nbsp;&nbsp;<span class="c1"># If the message cannot be recognized (see @grok_filter), we&#39;ll</span></div><div class='line' id='LC197'>&nbsp;&nbsp;<span class="c1"># treat it like the whole event.message is correct and try to fill</span></div><div class='line' id='LC198'>&nbsp;&nbsp;<span class="c1"># the missing pieces (host, priority, etc)</span></div><div class='line' id='LC199'>&nbsp;&nbsp;<span class="kp">public</span></div><div class='line' id='LC200'>&nbsp;&nbsp;<span class="k">def</span> <span class="nf">syslog_relay</span><span class="p">(</span><span class="n">event</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span></div><div class='line' id='LC201'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@grok_filter</span><span class="o">.</span><span class="n">filter</span><span class="p">(</span><span class="n">event</span><span class="p">)</span></div><div class='line' id='LC202'><br/></div><div class='line' id='LC203'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="o">!</span><span class="n">event</span><span class="o">.</span><span class="n">tags</span><span class="o">.</span><span class="n">include?</span><span class="p">(</span><span class="s2">&quot;_grokparsefailure&quot;</span><span class="p">)</span></div><div class='line' id='LC204'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># Per RFC3164, priority = (facility * 8) + severity</span></div><div class='line' id='LC205'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1">#                       = (facility &lt;&lt; 3) &amp; (severity)</span></div><div class='line' id='LC206'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">priority</span> <span class="o">=</span> <span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;priority&quot;</span><span class="o">].</span><span class="n">first</span><span class="o">.</span><span class="n">to_i</span> <span class="k">rescue</span> <span class="mi">13</span></div><div class='line' id='LC207'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">severity</span> <span class="o">=</span> <span class="n">priority</span> <span class="o">&amp;</span> <span class="mi">7</span>   <span class="c1"># 7 is 111 (3 bits)</span></div><div class='line' id='LC208'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">facility</span> <span class="o">=</span> <span class="n">priority</span> <span class="o">&gt;&gt;</span> <span class="mi">3</span></div><div class='line' id='LC209'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;priority&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="n">priority</span></div><div class='line' id='LC210'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;severity&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="n">severity</span></div><div class='line' id='LC211'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;facility&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="n">facility</span></div><div class='line' id='LC212'><br/></div><div class='line' id='LC213'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@date_filter</span><span class="o">.</span><span class="n">filter</span><span class="p">(</span><span class="n">event</span><span class="p">)</span></div><div class='line' id='LC214'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">else</span></div><div class='line' id='LC215'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="vi">@logger</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="s2">&quot;NOT SYSLOG&quot;</span><span class="p">,</span> <span class="ss">:message</span> <span class="o">=&gt;</span> <span class="n">event</span><span class="o">.</span><span class="n">message</span><span class="p">)</span></div><div class='line' id='LC216'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">url</span> <span class="o">=</span> <span class="s2">&quot;syslog://</span><span class="si">#{</span><span class="no">Socket</span><span class="o">.</span><span class="n">gethostname</span><span class="si">}</span><span class="s2">/&quot;</span> <span class="k">if</span> <span class="n">url</span> <span class="o">==</span> <span class="s2">&quot;syslog://127.0.0.1/&quot;</span></div><div class='line' id='LC217'><br/></div><div class='line' id='LC218'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># RFC3164 says unknown messages get pri=13</span></div><div class='line' id='LC219'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">priority</span> <span class="o">=</span> <span class="mi">13</span></div><div class='line' id='LC220'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;priority&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="mi">13</span></div><div class='line' id='LC221'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;severity&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="mi">5</span>   <span class="c1"># 13 &amp; 7 == 5</span></div><div class='line' id='LC222'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;facility&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="mi">1</span>   <span class="c1"># 13 &gt;&gt; 3 == 1</span></div><div class='line' id='LC223'><br/></div><div class='line' id='LC224'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># Don&#39;t need to modify the message, here.</span></div><div class='line' id='LC225'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># event.message = ...</span></div><div class='line' id='LC226'><br/></div><div class='line' id='LC227'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">source</span> <span class="o">=</span> <span class="n">url</span></div><div class='line' id='LC228'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC229'><br/></div><div class='line' id='LC230'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># Apply severity and facility metadata if</span></div><div class='line' id='LC231'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="c1"># use_labels =&gt; true</span></div><div class='line' id='LC232'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="vi">@use_labels</span></div><div class='line' id='LC233'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">facility_number</span> <span class="o">=</span> <span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;facility&quot;</span><span class="o">]</span></div><div class='line' id='LC234'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">severity_number</span> <span class="o">=</span> <span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;severity&quot;</span><span class="o">]</span></div><div class='line' id='LC235'><br/></div><div class='line' id='LC236'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="vi">@facility_labels</span><span class="o">[</span><span class="n">facility_number</span><span class="o">]</span></div><div class='line' id='LC237'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;facility_label&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="vi">@facility_labels</span><span class="o">[</span><span class="n">facility_number</span><span class="o">]</span></div><div class='line' id='LC238'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC239'><br/></div><div class='line' id='LC240'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">if</span> <span class="vi">@severity_labels</span><span class="o">[</span><span class="n">severity_number</span><span class="o">]</span></div><div class='line' id='LC241'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="n">event</span><span class="o">.</span><span class="n">fields</span><span class="o">[</span><span class="s2">&quot;severity_label&quot;</span><span class="o">]</span> <span class="o">=</span> <span class="vi">@severity_labels</span><span class="o">[</span><span class="n">severity_number</span><span class="o">]</span></div><div class='line' id='LC242'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC243'>&nbsp;&nbsp;&nbsp;&nbsp;<span class="k">end</span></div><div class='line' id='LC244'>&nbsp;&nbsp;<span class="k">end</span> <span class="c1"># def syslog_relay</span></div><div class='line' id='LC245'><span class="k">end</span> <span class="c1"># class LogStash::Inputs::Syslog</span></div></pre></div>
          </td>
        </tr>
      </table>
  </div>

          </div>
        </div>
      </div>
    </div>

  </div>

<div class="frame frame-loading large-loading-area" style="display:none;" data-tree-list-url="/logstash/logstash/tree-list/c455a1da340d107dd901d5c95e0403144a137822" data-blob-url-prefix="/logstash/logstash/blob/c455a1da340d107dd901d5c95e0403144a137822">
  <img src="https://a248.e.akamai.net/assets.github.com/images/spinners/octocat-spinner-64.gif?1329872008" height="64" width="64">
</div>

      </div>
      <div class="context-overlay"></div>
    </div>


      <!-- footer -->
      <div id="footer" >
        
  <div class="upper_footer">
     <div class="container clearfix">

       <!--[if IE]><h4 id="blacktocat_ie">GitHub Links</h4><![endif]-->
       <![if !IE]><h4 id="blacktocat">GitHub Links</h4><![endif]>

       <ul class="footer_nav">
         <h4>GitHub</h4>
         <li><a href="https://github.com/about">About</a></li>
         <li><a href="https://github.com/blog">Blog</a></li>
         <li><a href="https://github.com/features">Features</a></li>
         <li><a href="https://github.com/contact">Contact &amp; Support</a></li>
         <li><a href="https://github.com/training">Training</a></li>
         <li><a href="http://enterprise.github.com/">GitHub Enterprise</a></li>
         <li><a href="http://status.github.com/">Site Status</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Tools</h4>
         <li><a href="http://get.gaug.es/">Gauges: Analyze web traffic</a></li>
         <li><a href="http://speakerdeck.com">Speaker Deck: Presentations</a></li>
         <li><a href="https://gist.github.com">Gist: Code snippets</a></li>
         <li><a href="http://mac.github.com/">GitHub for Mac</a></li>
         <li><a href="http://mobile.github.com/">Issues for iPhone</a></li>
         <li><a href="http://jobs.github.com/">Job Board</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Extras</h4>
         <li><a href="http://shop.github.com/">GitHub Shop</a></li>
         <li><a href="http://octodex.github.com/">The Octodex</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Documentation</h4>
         <li><a href="http://help.github.com/">GitHub Help</a></li>
         <li><a href="http://developer.github.com/">Developer API</a></li>
         <li><a href="http://github.github.com/github-flavored-markdown/">GitHub Flavored Markdown</a></li>
         <li><a href="http://pages.github.com/">GitHub Pages</a></li>
       </ul>

     </div><!-- /.site -->
  </div><!-- /.upper_footer -->

<div class="lower_footer">
  <div class="container clearfix">
    <!--[if IE]><div id="legal_ie"><![endif]-->
    <![if !IE]><div id="legal"><![endif]>
      <ul>
          <li><a href="https://github.com/site/terms">Terms of Service</a></li>
          <li><a href="https://github.com/site/privacy">Privacy</a></li>
          <li><a href="https://github.com/security">Security</a></li>
      </ul>

      <p>&copy; 2012 <span title="0.06398s from fe6.rs.github.com">GitHub</span> Inc. All rights reserved.</p>
    </div><!-- /#legal or /#legal_ie-->

      <div class="sponsor">
        <a href="http://www.rackspace.com" class="logo">
          <img alt="Dedicated Server" height="36" src="https://a248.e.akamai.net/assets.github.com/images/modules/footer/rackspaces_logo.png?1329521041" width="38" />
        </a>
        Powered by the <a href="http://www.rackspace.com ">Dedicated
        Servers</a> and<br/> <a href="http://www.rackspacecloud.com">Cloud
        Computing</a> of Rackspace Hosting<span>&reg;</span>
      </div>
  </div><!-- /.site -->
</div><!-- /.lower_footer -->

      </div><!-- /#footer -->

    

<div id="keyboard_shortcuts_pane" class="instapaper_ignore readability-extra" style="display:none">
  <h2>Keyboard Shortcuts <small><a href="#" class="js-see-all-keyboard-shortcuts">(see all)</a></small></h2>

  <div class="columns threecols">
    <div class="column first">
      <h3>Site wide shortcuts</h3>
      <dl class="keyboard-mappings">
        <dt>s</dt>
        <dd>Focus site search</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>?</dt>
        <dd>Bring up this help dialog</dd>
      </dl>
    </div><!-- /.column.first -->

    <div class="column middle" style='display:none'>
      <h3>Commit list</h3>
      <dl class="keyboard-mappings">
        <dt>j</dt>
        <dd>Move selection down</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>k</dt>
        <dd>Move selection up</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>c <em>or</em> o <em>or</em> enter</dt>
        <dd>Open commit</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>y</dt>
        <dd>Expand URL to its canonical form</dd>
      </dl>
    </div><!-- /.column.first -->

    <div class="column last" style='display:none'>
      <h3>Pull request list</h3>
      <dl class="keyboard-mappings">
        <dt>j</dt>
        <dd>Move selection down</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>k</dt>
        <dd>Move selection up</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>o <em>or</em> enter</dt>
        <dd>Open issue</dd>
      </dl>
    </div><!-- /.columns.last -->

  </div><!-- /.columns.equacols -->

  <div style='display:none'>
    <div class="rule"></div>

    <h3>Issues</h3>

    <div class="columns threecols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt>j</dt>
          <dd>Move selection down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>k</dt>
          <dd>Move selection up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>x</dt>
          <dd>Toggle selection</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>o <em>or</em> enter</dt>
          <dd>Open issue</dd>
        </dl>
      </div><!-- /.column.first -->
      <div class="column middle">
        <dl class="keyboard-mappings">
          <dt>I</dt>
          <dd>Mark selection as read</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>U</dt>
          <dd>Mark selection as unread</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>e</dt>
          <dd>Close selection</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>y</dt>
          <dd>Remove selection from view</dd>
        </dl>
      </div><!-- /.column.middle -->
      <div class="column last">
        <dl class="keyboard-mappings">
          <dt>c</dt>
          <dd>Create issue</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>l</dt>
          <dd>Create label</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>i</dt>
          <dd>Back to inbox</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>u</dt>
          <dd>Back to issues</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>/</dt>
          <dd>Focus issues search</dd>
        </dl>
      </div>
    </div>
  </div>

  <div style='display:none'>
    <div class="rule"></div>

    <h3>Issues Dashboard</h3>

    <div class="columns threecols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt>j</dt>
          <dd>Move selection down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>k</dt>
          <dd>Move selection up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>o <em>or</em> enter</dt>
          <dd>Open issue</dd>
        </dl>
      </div><!-- /.column.first -->
    </div>
  </div>

  <div style='display:none'>
    <div class="rule"></div>

    <h3>Network Graph</h3>
    <div class="columns equacols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt><span class="badmono">←</span> <em>or</em> h</dt>
          <dd>Scroll left</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">→</span> <em>or</em> l</dt>
          <dd>Scroll right</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">↑</span> <em>or</em> k</dt>
          <dd>Scroll up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">↓</span> <em>or</em> j</dt>
          <dd>Scroll down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>t</dt>
          <dd>Toggle visibility of head labels</dd>
        </dl>
      </div><!-- /.column.first -->
      <div class="column last">
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">←</span> <em>or</em> shift h</dt>
          <dd>Scroll all the way left</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">→</span> <em>or</em> shift l</dt>
          <dd>Scroll all the way right</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">↑</span> <em>or</em> shift k</dt>
          <dd>Scroll all the way up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">↓</span> <em>or</em> shift j</dt>
          <dd>Scroll all the way down</dd>
        </dl>
      </div><!-- /.column.last -->
    </div>
  </div>

  <div >
    <div class="rule"></div>
    <div class="columns threecols">
      <div class="column first" >
        <h3>Source Code Browsing</h3>
        <dl class="keyboard-mappings">
          <dt>t</dt>
          <dd>Activates the file finder</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>l</dt>
          <dd>Jump to line</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>w</dt>
          <dd>Switch branch/tag</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>y</dt>
          <dd>Expand URL to its canonical form</dd>
        </dl>
      </div>
    </div>
  </div>
</div>

    <div id="markdown-help" class="instapaper_ignore readability-extra">
  <h2>Markdown Cheat Sheet</h2>

  <div class="cheatsheet-content">

  <div class="mod">
    <div class="col">
      <h3>Format Text</h3>
      <p>Headers</p>
      <pre>
# This is an &lt;h1&gt; tag
## This is an &lt;h2&gt; tag
###### This is an &lt;h6&gt; tag</pre>
     <p>Text styles</p>
     <pre>
*This text will be italic*
_This will also be italic_
**This text will be bold**
__This will also be bold__

*You **can** combine them*
</pre>
    </div>
    <div class="col">
      <h3>Lists</h3>
      <p>Unordered</p>
      <pre>
* Item 1
* Item 2
  * Item 2a
  * Item 2b</pre>
     <p>Ordered</p>
     <pre>
1. Item 1
2. Item 2
3. Item 3
   * Item 3a
   * Item 3b</pre>
    </div>
    <div class="col">
      <h3>Miscellaneous</h3>
      <p>Images</p>
      <pre>
![GitHub Logo](/images/logo.png)
Format: ![Alt Text](url)
</pre>
     <p>Links</p>
     <pre>
http://github.com - automatic!
[GitHub](http://github.com)</pre>
<p>Blockquotes</p>
     <pre>
As Kanye West said:

> We're living the future so
> the present is our past.
</pre>
    </div>
  </div>
  <div class="rule"></div>

  <h3>Code Examples in Markdown</h3>
  <div class="col">
      <p>Syntax highlighting with <a href="http://github.github.com/github-flavored-markdown/" title="GitHub Flavored Markdown" target="_blank">GFM</a></p>
      <pre>
```javascript
function fancyAlert(arg) {
  if(arg) {
    $.facebox({div:'#foo'})
  }
}
```</pre>
    </div>
    <div class="col">
      <p>Or, indent your code 4 spaces</p>
      <pre>
Here is a Python code example
without syntax highlighting:

    def foo:
      if not bar:
        return true</pre>
    </div>
    <div class="col">
      <p>Inline code for comments</p>
      <pre>
I think you should use an
`&lt;addr&gt;` element here instead.</pre>
    </div>
  </div>

  </div>
</div>


    <div class="ajax-error-message">
      <p><span class="icon"></span> Something went wrong with that request. Please try again. <a href="javascript:;" class="ajax-error-dismiss">Dismiss</a></p>
    </div>

    
    
    
    <span id='server_response_time' data-time='0.06521' data-host='fe6'></span>
  </body>
</html>

