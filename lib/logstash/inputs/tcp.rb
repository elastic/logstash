


<!DOCTYPE html>
<html lang="en" class="">
  <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# object: http://ogp.me/ns/object# article: http://ogp.me/ns/article# profile: http://ogp.me/ns/profile#">
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta http-equiv="Content-Language" content="en">
    <meta name="viewport" content="width=1020">
    
    
    <title>logstash/tcp.rb at 7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9 · elastic/logstash · GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub">
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub">
    <link rel="apple-touch-icon" sizes="57x57" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="114x114" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="72x72" href="/apple-touch-icon-144.png">
    <link rel="apple-touch-icon" sizes="144x144" href="/apple-touch-icon-144.png">
    <meta property="fb:app_id" content="1401488693436528">

      <meta content="@github" name="twitter:site" /><meta content="summary" name="twitter:card" /><meta content="elastic/logstash" name="twitter:title" /><meta content="logstash - transport and process your logs, events, or other data" name="twitter:description" /><meta content="https://avatars0.githubusercontent.com/u/6764390?v=3&amp;s=400" name="twitter:image:src" />
      <meta content="GitHub" property="og:site_name" /><meta content="object" property="og:type" /><meta content="https://avatars0.githubusercontent.com/u/6764390?v=3&amp;s=400" property="og:image" /><meta content="elastic/logstash" property="og:title" /><meta content="https://github.com/elastic/logstash" property="og:url" /><meta content="logstash - transport and process your logs, events, or other data" property="og:description" />
      <meta name="browser-stats-url" content="https://api.github.com/_private/browser/stats">
    <meta name="browser-errors-url" content="https://api.github.com/_private/browser/errors">
    <link rel="assets" href="https://assets-cdn.github.com/">
    
    <meta name="pjax-timeout" content="1000">
    

    <meta name="msapplication-TileImage" content="/windows-tile.png">
    <meta name="msapplication-TileColor" content="#ffffff">
    <meta name="selected-link" value="repo_source" data-pjax-transient>

        <meta name="google-analytics" content="UA-3769691-2">

    <meta content="collector.githubapp.com" name="octolytics-host" /><meta content="collector-cdn.github.com" name="octolytics-script-host" /><meta content="github" name="octolytics-app-id" /><meta content="252C013A:44D6:6A98E7F:55BF869B" name="octolytics-dimension-request_id" />
    
    <meta content="Rails, view, blob#show" data-pjax-transient="true" name="analytics-event" />
    <meta class="js-ga-set" name="dimension1" content="Logged Out">
      <meta class="js-ga-set" name="dimension4" content="Current repo nav">
    <meta name="is-dotcom" content="true">
        <meta name="hostname" content="github.com">
    <meta name="user-login" content="">

      <link rel="icon" sizes="any" mask href="https://assets-cdn.github.com/pinned-octocat.svg">
      <meta name="theme-color" content="#4078c0">
      <link rel="icon" type="image/x-icon" href="https://assets-cdn.github.com/favicon.ico">

    <!-- </textarea> --><!-- '"` --><meta content="authenticity_token" name="csrf-param" />
<meta content="dgC7VYZfBQrTP+4PfRnKyZxa1IVQ2s8km2NI8oDUPVOrdgsInXFDBfojlwUlIVIP7au/K7Cb6eC78clmRAOb0A==" name="csrf-token" />
    

    <link crossorigin="anonymous" href="https://assets-cdn.github.com/assets/github/index-c7126cd67871e693a9f863b7a0e99879ca39079b15a8784f8b543c03bf14ad72.css" media="all" rel="stylesheet" />
    <link crossorigin="anonymous" href="https://assets-cdn.github.com/assets/github2/index-87247f16e6450ef54cb0eda3f8f1484e33a3f18c7a7d3df1f76f67cba36a8d6d.css" media="all" rel="stylesheet" />
    
    


    <meta http-equiv="x-pjax-version" content="f8fdf7d6713452aadb5c847c2e94f51b">

      
  <meta name="description" content="logstash - transport and process your logs, events, or other data">
  <meta name="go-import" content="github.com/elastic/logstash git https://github.com/elastic/logstash.git">

  <meta content="6764390" name="octolytics-dimension-user_id" /><meta content="elastic" name="octolytics-dimension-user_login" /><meta content="1090311" name="octolytics-dimension-repository_id" /><meta content="elastic/logstash" name="octolytics-dimension-repository_nwo" /><meta content="true" name="octolytics-dimension-repository_public" /><meta content="false" name="octolytics-dimension-repository_is_fork" /><meta content="1090311" name="octolytics-dimension-repository_network_root_id" /><meta content="elastic/logstash" name="octolytics-dimension-repository_network_root_nwo" />
  <link href="https://github.com/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9.atom" rel="alternate" title="Recent Commits to logstash:7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" type="application/atom+xml">

  </head>


  <body class="logged_out  env-production  vis-public page-blob">
    <a href="#start-of-content" tabindex="1" class="accessibility-aid js-skip-to-content">Skip to content</a>
    <div class="wrapper">
      
      
      



        
        <div class="header header-logged-out" role="banner">
  <div class="container clearfix">

    <a class="header-logo-wordmark" href="https://github.com/" data-ga-click="(Logged out) Header, go to homepage, icon:logo-wordmark">
      <span class="mega-octicon octicon-logo-github"></span>
    </a>

    <div class="header-actions" role="navigation">
        <a class="btn btn-primary" href="/join" data-ga-click="(Logged out) Header, clicked Sign up, text:sign-up">Sign up</a>
      <a class="btn" href="/login?return_to=%2Felastic%2Flogstash%2Fblob%2F7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9%2Flib%2Flogstash%2Finputs%2Ftcp.rb" data-ga-click="(Logged out) Header, clicked Sign in, text:sign-in">Sign in</a>
    </div>

    <div class="site-search repo-scope js-site-search" role="search">
      <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/elastic/logstash/search" class="js-site-search-form" data-global-search-url="/search" data-repo-search-url="/elastic/logstash/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <label class="js-chromeless-input-container form-control">
    <div class="scope-badge">This repository</div>
    <input type="text"
      class="js-site-search-focus js-site-search-field is-clearable chromeless-input"
      data-hotkey="s"
      name="q"
      placeholder="Search"
      aria-label="Search this repository"
      data-global-scope-placeholder="Search GitHub"
      data-repo-scope-placeholder="Search"
      tabindex="1"
      autocapitalize="off">
  </label>
</form>
    </div>

      <ul class="header-nav left" role="navigation">
          <li class="header-nav-item">
            <a class="header-nav-link" href="/explore" data-ga-click="(Logged out) Header, go to explore, text:explore">Explore</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="/features" data-ga-click="(Logged out) Header, go to features, text:features">Features</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="https://enterprise.github.com/" data-ga-click="(Logged out) Header, go to enterprise, text:enterprise">Enterprise</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="/blog" data-ga-click="(Logged out) Header, go to blog, text:blog">Blog</a>
          </li>
      </ul>

  </div>
</div>



      <div id="start-of-content" class="accessibility-aid"></div>
          <div class="site" itemscope itemtype="http://schema.org/WebPage">
    <div id="js-flash-container">
      
    </div>
    <div class="pagehead repohead instapaper_ignore readability-menu ">
      <div class="container">

        <div class="clearfix">
          
<ul class="pagehead-actions">

  <li>
      <a href="/login?return_to=%2Felastic%2Flogstash"
    class="btn btn-sm btn-with-count tooltipped tooltipped-n"
    aria-label="You must be signed in to watch a repository" rel="nofollow">
    <span class="octicon octicon-eye"></span>
    Watch
  </a>
  <a class="social-count" href="/elastic/logstash/watchers">
    403
  </a>

  </li>

  <li>
      <a href="/login?return_to=%2Felastic%2Flogstash"
    class="btn btn-sm btn-with-count tooltipped tooltipped-n"
    aria-label="You must be signed in to star a repository" rel="nofollow">
    <span class="octicon octicon-star"></span>
    Star
  </a>

    <a class="social-count js-social-count" href="/elastic/logstash/stargazers">
      4,534
    </a>

  </li>

    <li>
      <a href="/login?return_to=%2Felastic%2Flogstash"
        class="btn btn-sm btn-with-count tooltipped tooltipped-n"
        aria-label="You must be signed in to fork a repository" rel="nofollow">
        <span class="octicon octicon-repo-forked"></span>
        Fork
      </a>
      <a href="/elastic/logstash/network" class="social-count">
        1,505
      </a>
    </li>
</ul>

          <h1 itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="entry-title public ">
            <span class="mega-octicon octicon-repo"></span>
            <span class="author"><a href="/elastic" class="url fn" itemprop="url" rel="author"><span itemprop="title">elastic</span></a></span><!--
         --><span class="path-divider">/</span><!--
         --><strong><a href="/elastic/logstash" data-pjax="#js-repo-pjax-container">logstash</a></strong>

            <span class="page-context-loader">
              <img alt="" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
            </span>

          </h1>
        </div>

      </div>
    </div>

      <div class="container">
        <div class="repository-with-sidebar repo-container new-discussion-timeline ">
          <div class="repository-sidebar clearfix">
              

<nav class="sunken-menu repo-nav js-repo-nav js-sidenav-container-pjax js-octicon-loaders"
     role="navigation"
     data-pjax="#js-repo-pjax-container"
     data-issue-count-url="/elastic/logstash/issues/counts">
  <ul class="sunken-menu-group">
    <li class="tooltipped tooltipped-w" aria-label="Code">
      <a href="/elastic/logstash" aria-label="Code" aria-selected="true" class="js-selected-navigation-item selected sunken-menu-item" data-hotkey="g c" data-selected-links="repo_source repo_downloads repo_commits repo_releases repo_tags repo_branches /elastic/logstash">
        <span class="octicon octicon-code"></span> <span class="full-word">Code</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>

      <li class="tooltipped tooltipped-w" aria-label="Issues">
        <a href="/elastic/logstash/issues" aria-label="Issues" class="js-selected-navigation-item sunken-menu-item" data-hotkey="g i" data-selected-links="repo_issues repo_labels repo_milestones /elastic/logstash/issues">
          <span class="octicon octicon-issue-opened"></span> <span class="full-word">Issues</span>
          <span class="js-issue-replace-counter"></span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>

    <li class="tooltipped tooltipped-w" aria-label="Pull requests">
      <a href="/elastic/logstash/pulls" aria-label="Pull requests" class="js-selected-navigation-item sunken-menu-item" data-hotkey="g p" data-selected-links="repo_pulls /elastic/logstash/pulls">
          <span class="octicon octicon-git-pull-request"></span> <span class="full-word">Pull requests</span>
          <span class="js-pull-replace-counter"></span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>

      <li class="tooltipped tooltipped-w" aria-label="Wiki">
        <a href="/elastic/logstash/wiki" aria-label="Wiki" class="js-selected-navigation-item sunken-menu-item" data-hotkey="g w" data-selected-links="repo_wiki /elastic/logstash/wiki">
          <span class="octicon octicon-book"></span> <span class="full-word">Wiki</span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>      </li>
  </ul>
  <div class="sunken-menu-separator"></div>
  <ul class="sunken-menu-group">

    <li class="tooltipped tooltipped-w" aria-label="Pulse">
      <a href="/elastic/logstash/pulse" aria-label="Pulse" class="js-selected-navigation-item sunken-menu-item" data-selected-links="pulse /elastic/logstash/pulse">
        <span class="octicon octicon-pulse"></span> <span class="full-word">Pulse</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>

    <li class="tooltipped tooltipped-w" aria-label="Graphs">
      <a href="/elastic/logstash/graphs" aria-label="Graphs" class="js-selected-navigation-item sunken-menu-item" data-selected-links="repo_graphs repo_contributors /elastic/logstash/graphs">
        <span class="octicon octicon-graph"></span> <span class="full-word">Graphs</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>
  </ul>


</nav>

                <div class="only-with-full-nav">
                    
<div class="js-clone-url clone-url open"
  data-protocol-type="http">
  <h3><span class="text-emphasized">HTTPS</span> clone URL</h3>
  <div class="input-group js-zeroclipboard-container">
    <input type="text" class="input-mini input-monospace js-url-field js-zeroclipboard-target"
           value="https://github.com/elastic/logstash.git" readonly="readonly" aria-label="HTTPS clone URL">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>

  
<div class="js-clone-url clone-url "
  data-protocol-type="subversion">
  <h3><span class="text-emphasized">Subversion</span> checkout URL</h3>
  <div class="input-group js-zeroclipboard-container">
    <input type="text" class="input-mini input-monospace js-url-field js-zeroclipboard-target"
           value="https://github.com/elastic/logstash" readonly="readonly" aria-label="Subversion checkout URL">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>



  <div class="clone-options">You can clone with
    <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/users/set_protocol?protocol_selector=http&amp;protocol_type=clone" class="inline-form js-clone-selector-form " data-form-nonce="a442a9886750c44efec812f16020991ebadea111" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="1ELj3mzR2Zxb5uQwxF8n3ku/Rl0PdYsbn3XV7uGnTeHv1kzUH7+uWzxcpLdflz08FRROMLvW4sALJOydatQ3Sw==" /></div><button class="btn-link js-clone-selector" data-protocol="http" type="submit">HTTPS</button></form> or <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/users/set_protocol?protocol_selector=subversion&amp;protocol_type=clone" class="inline-form js-clone-selector-form " data-form-nonce="a442a9886750c44efec812f16020991ebadea111" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="3Ge8+7uRKsxZ0U5KAK2/N97A7BrvcsGODyNFlIfpk5fxIV2TSNkPENqI+tBwrSq+4pxhv4JkgZKiWSwJBBKCjA==" /></div><button class="btn-link js-clone-selector" data-protocol="subversion" type="submit">Subversion</button></form>.
    <a href="https://help.github.com/articles/which-remote-url-should-i-use" class="help tooltipped tooltipped-n" aria-label="Get help on which URL is right for you.">
      <span class="octicon octicon-question"></span>
    </a>
  </div>

                  <a href="/elastic/logstash/archive/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9.zip"
                     class="btn btn-sm sidebar-button"
                     aria-label="Download the contents of elastic/logstash as a zip file"
                     title="Download the contents of elastic/logstash as a zip file"
                     rel="nofollow">
                    <span class="octicon octicon-cloud-download"></span>
                    Download ZIP
                  </a>
                </div>
          </div>
          <div id="js-repo-pjax-container" class="repository-content context-loader-container" data-pjax-container>

            

<a href="/elastic/logstash/blob/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb" class="hidden js-permalink-shortcut" data-hotkey="y">Permalink</a>

<!-- blob contrib key: blob_contributors:v21:d4706b4c8c67e856a9d0e9d0785d60b5 -->

  <div class="file-navigation js-zeroclipboard-container">
    
<div class="select-menu js-menu-container js-select-menu left">
  <span class="btn btn-sm select-menu-button js-menu-target css-truncate" data-hotkey="w"
    data-ref=""
    title=""
    role="button" aria-label="Switch branches or tags" tabindex="0" aria-haspopup="true">
    <i>Tree:</i>
    <span class="js-select-button css-truncate-target">7b6ab95124</span>
  </span>

  <div class="select-menu-modal-holder js-menu-content js-navigation-container" data-pjax aria-hidden="true">

    <div class="select-menu-modal">
      <div class="select-menu-header">
        <span class="select-menu-title">Switch branches/tags</span>
        <span class="octicon octicon-x js-menu-close" role="button" aria-label="Close"></span>
      </div>

      <div class="select-menu-filters">
        <div class="select-menu-text-filter">
          <input type="text" aria-label="Filter branches/tags" id="context-commitish-filter-field" class="js-filterable-field js-navigation-enable" placeholder="Filter branches/tags">
        </div>
        <div class="select-menu-tabs">
          <ul>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="branches" data-filter-placeholder="Filter branches/tags" class="js-select-menu-tab" role="tab">Branches</a>
            </li>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="tags" data-filter-placeholder="Find a tag…" class="js-select-menu-tab" role="tab">Tags</a>
            </li>
          </ul>
        </div>
      </div>

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="branches" role="menu">

        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/1.3.x/lib/logstash/inputs/tcp.rb"
               data-name="1.3.x"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="1.3.x">
                1.3.x
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/1.4/lib/logstash/inputs/tcp.rb"
               data-name="1.4"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="1.4">
                1.4
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/1.5/lib/logstash/inputs/tcp.rb"
               data-name="1.5"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="1.5">
                1.5
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/1.6/lib/logstash/inputs/tcp.rb"
               data-name="1.6"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="1.6">
                1.6
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/LOGSTASH-1509/lib/logstash/inputs/tcp.rb"
               data-name="LOGSTASH-1509"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="LOGSTASH-1509">
                LOGSTASH-1509
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/add_heap_docs/lib/logstash/inputs/tcp.rb"
               data-name="add_heap_docs"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="add_heap_docs">
                add_heap_docs
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/bug/fix-es-embedded-startup-delay/lib/logstash/inputs/tcp.rb"
               data-name="bug/fix-es-embedded-startup-delay"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="bug/fix-es-embedded-startup-delay">
                bug/fix-es-embedded-startup-delay
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/bump_versions/lib/logstash/inputs/tcp.rb"
               data-name="bump_versions"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="bump_versions">
                bump_versions
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/bundler_cleanups/lib/logstash/inputs/tcp.rb"
               data-name="bundler_cleanups"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="bundler_cleanups">
                bundler_cleanups
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/dotgem/lib/logstash/inputs/tcp.rb"
               data-name="dotgem"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="dotgem">
                dotgem
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/es-config/lib/logstash/inputs/tcp.rb"
               data-name="es-config"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="es-config">
                es-config
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/feature/faster_json/lib/logstash/inputs/tcp.rb"
               data-name="feature/faster_json"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="feature/faster_json">
                feature/faster_json
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/feature/filter-flushing-execution/lib/logstash/inputs/tcp.rb"
               data-name="feature/filter-flushing-execution"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="feature/filter-flushing-execution">
                feature/filter-flushing-execution
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/feature/integration_tests/lib/logstash/inputs/tcp.rb"
               data-name="feature/integration_tests"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="feature/integration_tests">
                feature/integration_tests
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/feature/java_backend/lib/logstash/inputs/tcp.rb"
               data-name="feature/java_backend"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="feature/java_backend">
                feature/java_backend
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/feature/persistent_queue/lib/logstash/inputs/tcp.rb"
               data-name="feature/persistent_queue"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="feature/persistent_queue">
                feature/persistent_queue
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/conditionals/lib/logstash/inputs/tcp.rb"
               data-name="fix/conditionals"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/conditionals">
                fix/conditionals
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/drip/lib/logstash/inputs/tcp.rb"
               data-name="fix/drip"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/drip">
                fix/drip
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/gem_paths/lib/logstash/inputs/tcp.rb"
               data-name="fix/gem_paths"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/gem_paths">
                fix/gem_paths
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/java8_merge/lib/logstash/inputs/tcp.rb"
               data-name="fix/java8_merge"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/java8_merge">
                fix/java8_merge
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/perf_regression/lib/logstash/inputs/tcp.rb"
               data-name="fix/perf_regression"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/perf_regression">
                fix/perf_regression
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/remove_field_array_item/lib/logstash/inputs/tcp.rb"
               data-name="fix/remove_field_array_item"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/remove_field_array_item">
                fix/remove_field_array_item
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/remove-lock-flush/lib/logstash/inputs/tcp.rb"
               data-name="fix/remove-lock-flush"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/remove-lock-flush">
                fix/remove-lock-flush
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/fix/twitter_keys/lib/logstash/inputs/tcp.rb"
               data-name="fix/twitter_keys"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix/twitter_keys">
                fix/twitter_keys
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/jenkins/lib/logstash/inputs/tcp.rb"
               data-name="jenkins"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="jenkins">
                jenkins
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/master/lib/logstash/inputs/tcp.rb"
               data-name="master"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="master">
                master
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/mri/simple/lib/logstash/inputs/tcp.rb"
               data-name="mri/simple"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="mri/simple">
                mri/simple
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/old_and_confused_1.4/lib/logstash/inputs/tcp.rb"
               data-name="old_and_confused_1.4"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="old_and_confused_1.4">
                old_and_confused_1.4
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/pr/1430/lib/logstash/inputs/tcp.rb"
               data-name="pr/1430"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="pr/1430">
                pr/1430
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/pr/3009/lib/logstash/inputs/tcp.rb"
               data-name="pr/3009"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="pr/3009">
                pr/3009
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/refactor_agent/lib/logstash/inputs/tcp.rb"
               data-name="refactor_agent"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="refactor_agent">
                refactor_agent
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/s3-input-default-region-bug/lib/logstash/inputs/tcp.rb"
               data-name="s3-input-default-region-bug"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="s3-input-default-region-bug">
                s3-input-default-region-bug
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/some-compressor-patch-i-forgot/lib/logstash/inputs/tcp.rb"
               data-name="some-compressor-patch-i-forgot"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="some-compressor-patch-i-forgot">
                some-compressor-patch-i-forgot
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/tooling/use-ruby-for-building/lib/logstash/inputs/tcp.rb"
               data-name="tooling/use-ruby-for-building"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="tooling/use-ruby-for-building">
                tooling/use-ruby-for-building
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/v1.4.3-build/lib/logstash/inputs/tcp.rb"
               data-name="v1.4.3-build"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="v1.4.3-build">
                v1.4.3-build
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/windows/bin-plugin/lib/logstash/inputs/tcp.rb"
               data-name="windows/bin-plugin"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="windows/bin-plugin">
                windows/bin-plugin
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/windows/rake-bootstrap/lib/logstash/inputs/tcp.rb"
               data-name="windows/rake-bootstrap"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="windows/rake-bootstrap">
                windows/rake-bootstrap
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/wip/bundle-move-jls/lib/logstash/inputs/tcp.rb"
               data-name="wip/bundle-move-jls"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="wip/bundle-move-jls">
                wip/bundle-move-jls
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/elastic/logstash/blob/wip/bundler-move/lib/logstash/inputs/tcp.rb"
               data-name="wip/bundler-move"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="wip/bundler-move">
                wip/bundler-move
              </span>
            </a>
        </div>

          <div class="select-menu-no-results">Nothing to show</div>
      </div>

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="tags">
        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.3.snapshot2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.3.snapshot2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.3.snapshot2">v1.5.3.snapshot2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.3.snapshot1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.3.snapshot1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.3.snapshot1">v1.5.3.snapshot1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.3">v1.5.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.2.snapshot2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.2.snapshot2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.2.snapshot2">v1.5.2.snapshot2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.2.snapshot1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.2.snapshot1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.2.snapshot1">v1.5.2.snapshot1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.2">v1.5.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.1.snapshot1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.1.snapshot1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.1.snapshot1">v1.5.1.snapshot1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.1">v1.5.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0.snapshot1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0.snapshot1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0.snapshot1">v1.5.0.snapshot1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc4.snapshot2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc4.snapshot2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc4.snapshot2">v1.5.0-rc4.snapshot2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0.rc4/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0.rc4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0.rc4">v1.5.0.rc4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc3.snapshot5/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc3.snapshot5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc3.snapshot5">v1.5.0-rc3.snapshot5</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc3.snapshot3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc3.snapshot3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc3.snapshot3">v1.5.0-rc3.snapshot3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc3.snapshot2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc3.snapshot2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc3.snapshot2">v1.5.0-rc3.snapshot2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc3.snapshot1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc3.snapshot1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc3.snapshot1">v1.5.0-rc3.snapshot1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0-rc3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0-rc3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0-rc3">v1.5.0-rc3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0.rc2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0.rc2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0.rc2">v1.5.0.rc2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0.rc1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0.rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0.rc1">v1.5.0.rc1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0.beta1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0.beta1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0.beta1">v1.5.0.beta1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.5.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.5.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.5.0">v1.5.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.4/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.4">v1.4.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.3">v1.4.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.2">v1.4.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.1">v1.4.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.0.rc1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.0.rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.0.rc1">v1.4.0.rc1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.0.beta2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.0.beta2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.0.beta2">v1.4.0.beta2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.0.beta1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.0.beta1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.0.beta1">v1.4.0.beta1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.4.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.4.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.4.0">v1.4.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.3.3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.3.3">v1.3.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.3.2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.3.2">v1.3.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.3.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.3.1">v1.3.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.3.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.3.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.3.0">v1.3.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.2.2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.2.2">v1.2.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.2.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.2.1">v1.2.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.2.0.beta2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.2.0.beta2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.2.0.beta2">v1.2.0.beta2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.2.0.beta1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.2.0.beta1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.2.0.beta1">v1.2.0.beta1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.2.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.2.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.2.0">v1.2.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.13/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.13"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.13">v1.1.13</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.12/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.12"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.12">v1.1.12</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.11/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.11"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.11">v1.1.11</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.10/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.10"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.10">v1.1.10</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.9/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.9">v1.1.9</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.8/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.8">v1.1.8</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.7/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.7">v1.1.7</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.6/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.6">v1.1.6</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.5/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.5">v1.1.5</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.4/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.4">v1.1.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.3/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.3">v1.1.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.2/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.2">v1.1.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.1-rc1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.1-rc1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.1-rc1">v1.1.1-rc1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.1">v1.1.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.0beta9/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.0beta9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.0beta9">v1.1.0beta9</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.0beta8/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.0beta8"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.0beta8">v1.1.0beta8</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.0beta7/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.0beta7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.0beta7">v1.1.0beta7</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.0.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.0.1">v1.1.0.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.1.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.1.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.1.0">v1.1.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.17/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.17"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.17">v1.0.17</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.16/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.16"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.16">v1.0.16</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.15/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.15"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.15">v1.0.15</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.14/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.14"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.14">v1.0.14</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.12/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.12"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.12">v1.0.12</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.11/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.11"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.11">v1.0.11</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.10/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.10"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.10">v1.0.10</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.9/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.9"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.9">v1.0.9</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.7/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.7"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.7">v1.0.7</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.6/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.6"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.6">v1.0.6</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.5/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.5"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.5">v1.0.5</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.4/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.4">v1.0.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.1/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.1">v1.0.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v1.0.0/lib/logstash/inputs/tcp.rb"
                 data-name="v1.0.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v1.0.0">v1.0.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/v/lib/logstash/inputs/tcp.rb"
                 data-name="v"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v">v</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/pull/2203/lib/logstash/inputs/tcp.rb"
                 data-name="pull/2203"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="pull/2203">pull/2203</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/now/lib/logstash/inputs/tcp.rb"
                 data-name="now"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="now">now</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/elastic/logstash/tree/1.0.4/lib/logstash/inputs/tcp.rb"
                 data-name="1.0.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="1.0.4">1.0.4</a>
            </div>
        </div>

        <div class="select-menu-no-results">Nothing to show</div>
      </div>

    </div>
  </div>
</div>

    <div class="btn-group right">
      <a href="/elastic/logstash/find/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9"
            class="js-show-file-finder btn btn-sm empty-icon tooltipped tooltipped-nw"
            data-pjax
            data-hotkey="t"
            aria-label="Quickly jump between files">
        <span class="octicon octicon-list-unordered"></span>
      </a>
      <button aria-label="Copy file path to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </div>

    <div class="breadcrumb js-zeroclipboard-target">
      <span class="repo-root js-repo-root"><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/elastic/logstash/tree/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" class="" data-branch="7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" data-pjax="true" itemscope="url" rel="nofollow"><span itemprop="title">logstash</span></a></span></span><span class="separator">/</span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/elastic/logstash/tree/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib" class="" data-branch="7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" data-pjax="true" itemscope="url" rel="nofollow"><span itemprop="title">lib</span></a></span><span class="separator">/</span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/elastic/logstash/tree/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash" class="" data-branch="7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" data-pjax="true" itemscope="url" rel="nofollow"><span itemprop="title">logstash</span></a></span><span class="separator">/</span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/elastic/logstash/tree/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs" class="" data-branch="7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" data-pjax="true" itemscope="url" rel="nofollow"><span itemprop="title">inputs</span></a></span><span class="separator">/</span><strong class="final-path">tcp.rb</strong>
    </div>
  </div>


  <div class="commit file-history-tease">
    <div class="file-history-tease-header">
        <img alt="@colinsurprenant" class="avatar" height="24" src="https://avatars2.githubusercontent.com/u/2010?v=3&amp;s=48" width="24" />
        <span class="author"><a href="/colinsurprenant" rel="contributor">colinsurprenant</a></span>
        <time datetime="2014-07-11T20:02:23Z" is="relative-time">Jul 11, 2014</time>
        <div class="commit-title">
            <a href="/elastic/logstash/commit/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9" class="message" data-pjax="true" title="fix connection threads tracking leak

better mutex name, loop with while true

event per connection &amp; thread cleanups specs

remove leftover

closes #1509">fix connection threads tracking leak</a>
        </div>
    </div>

    <div class="participation">
      <p class="quickstat">
        <a href="#blob_contributors_box" rel="facebox">
          <strong>13</strong>
           contributors
        </a>
      </p>
          <a class="avatar-link tooltipped tooltipped-s" aria-label="jordansissel" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=jordansissel"><img alt="@jordansissel" class="avatar" height="20" src="https://avatars0.githubusercontent.com/u/131818?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="fetep" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=fetep"><img alt="@fetep" class="avatar" height="20" src="https://avatars2.githubusercontent.com/u/314078?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="nickethier" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=nickethier"><img alt="@nickethier" class="avatar" height="20" src="https://avatars1.githubusercontent.com/u/766500?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="wiibaa" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=wiibaa"><img alt="@wiibaa" class="avatar" height="20" src="https://avatars0.githubusercontent.com/u/659227?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="dpiddy" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=dpiddy"><img alt="@dpiddy" class="avatar" height="20" src="https://avatars3.githubusercontent.com/u/2182?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="mrichar1" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=mrichar1"><img alt="@mrichar1" class="avatar" height="20" src="https://avatars3.githubusercontent.com/u/478653?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="kurtado" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=kurtado"><img alt="@kurtado" class="avatar" height="20" src="https://avatars2.githubusercontent.com/u/1161427?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="Ludovicus" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=Ludovicus"><img alt="@Ludovicus" class="avatar" height="20" src="https://avatars0.githubusercontent.com/u/559818?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="lusis" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=lusis"><img alt="@lusis" class="avatar" height="20" src="https://avatars2.githubusercontent.com/u/228958?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="electrical" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=electrical"><img alt="@electrical" class="avatar" height="20" src="https://avatars2.githubusercontent.com/u/271677?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="colinsurprenant" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=colinsurprenant"><img alt="@colinsurprenant" class="avatar" height="20" src="https://avatars0.githubusercontent.com/u/2010?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="bernd" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=bernd"><img alt="@bernd" class="avatar" height="20" src="https://avatars1.githubusercontent.com/u/461?v=3&amp;s=40" width="20" /> </a>
    <a class="avatar-link tooltipped tooltipped-s" aria-label="avishai-ish-shalom" href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb?author=avishai-ish-shalom"><img alt="@avishai-ish-shalom" class="avatar" height="20" src="https://avatars3.githubusercontent.com/u/174628?v=3&amp;s=40" width="20" /> </a>


    </div>
    <div id="blob_contributors_box" style="display:none">
      <h2 class="facebox-header">Users who have contributed to this file</h2>
      <ul class="facebox-user-list">
          <li class="facebox-user-list-item">
            <img alt="@jordansissel" height="24" src="https://avatars2.githubusercontent.com/u/131818?v=3&amp;s=48" width="24" />
            <a href="/jordansissel">jordansissel</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@fetep" height="24" src="https://avatars0.githubusercontent.com/u/314078?v=3&amp;s=48" width="24" />
            <a href="/fetep">fetep</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@nickethier" height="24" src="https://avatars3.githubusercontent.com/u/766500?v=3&amp;s=48" width="24" />
            <a href="/nickethier">nickethier</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@wiibaa" height="24" src="https://avatars2.githubusercontent.com/u/659227?v=3&amp;s=48" width="24" />
            <a href="/wiibaa">wiibaa</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@dpiddy" height="24" src="https://avatars1.githubusercontent.com/u/2182?v=3&amp;s=48" width="24" />
            <a href="/dpiddy">dpiddy</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@mrichar1" height="24" src="https://avatars1.githubusercontent.com/u/478653?v=3&amp;s=48" width="24" />
            <a href="/mrichar1">mrichar1</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@kurtado" height="24" src="https://avatars0.githubusercontent.com/u/1161427?v=3&amp;s=48" width="24" />
            <a href="/kurtado">kurtado</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@Ludovicus" height="24" src="https://avatars2.githubusercontent.com/u/559818?v=3&amp;s=48" width="24" />
            <a href="/Ludovicus">Ludovicus</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@lusis" height="24" src="https://avatars0.githubusercontent.com/u/228958?v=3&amp;s=48" width="24" />
            <a href="/lusis">lusis</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@electrical" height="24" src="https://avatars0.githubusercontent.com/u/271677?v=3&amp;s=48" width="24" />
            <a href="/electrical">electrical</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@colinsurprenant" height="24" src="https://avatars2.githubusercontent.com/u/2010?v=3&amp;s=48" width="24" />
            <a href="/colinsurprenant">colinsurprenant</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@bernd" height="24" src="https://avatars3.githubusercontent.com/u/461?v=3&amp;s=48" width="24" />
            <a href="/bernd">bernd</a>
          </li>
          <li class="facebox-user-list-item">
            <img alt="@avishai-ish-shalom" height="24" src="https://avatars1.githubusercontent.com/u/174628?v=3&amp;s=48" width="24" />
            <a href="/avishai-ish-shalom">avishai-ish-shalom</a>
          </li>
      </ul>
    </div>
  </div>

<div class="file">
  <div class="file-header">
    <div class="file-actions">

      <div class="btn-group">
        <a href="/elastic/logstash/raw/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb" class="btn btn-sm " id="raw-url">Raw</a>
          <a href="/elastic/logstash/blame/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb" class="btn btn-sm js-update-url-with-hash">Blame</a>
        <a href="/elastic/logstash/commits/7b6ab95124cb1b4107e15ae78aeb2e4e4bb4c6d9/lib/logstash/inputs/tcp.rb" class="btn btn-sm " rel="nofollow">History</a>
      </div>


          <button type="button" class="octicon-btn disabled tooltipped tooltipped-n" aria-label="You must be signed in to make or propose changes">
            <span class="octicon octicon-pencil"></span>
          </button>

        <button type="button" class="octicon-btn octicon-btn-danger disabled tooltipped tooltipped-n" aria-label="You must be signed in to make or propose changes">
          <span class="octicon octicon-trashcan"></span>
        </button>
    </div>

    <div class="file-info">
        239 lines (208 sloc)
        <span class="file-info-divider"></span>
      7.642 kB
    </div>
  </div>
  

  <div class="blob-wrapper data type-ruby">
      <table class="highlight tab-size js-file-line-container" data-tab-size="8">
      <tr>
        <td id="L1" class="blob-num js-line-number" data-line-number="1"></td>
        <td id="LC1" class="blob-code blob-code-inner js-file-line"><span class="pl-c"># encoding: utf-8</span></td>
      </tr>
      <tr>
        <td id="L2" class="blob-num js-line-number" data-line-number="2"></td>
        <td id="LC2" class="blob-code blob-code-inner js-file-line"><span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>logstash/inputs/base<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L3" class="blob-num js-line-number" data-line-number="3"></td>
        <td id="LC3" class="blob-code blob-code-inner js-file-line"><span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>logstash/namespace<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L4" class="blob-num js-line-number" data-line-number="4"></td>
        <td id="LC4" class="blob-code blob-code-inner js-file-line"><span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>logstash/util/socket_peer<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L5" class="blob-num js-line-number" data-line-number="5"></td>
        <td id="LC5" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L6" class="blob-num js-line-number" data-line-number="6"></td>
        <td id="LC6" class="blob-code blob-code-inner js-file-line"><span class="pl-c"># Read events over a TCP socket.</span></td>
      </tr>
      <tr>
        <td id="L7" class="blob-num js-line-number" data-line-number="7"></td>
        <td id="LC7" class="blob-code blob-code-inner js-file-line"><span class="pl-c">#</span></td>
      </tr>
      <tr>
        <td id="L8" class="blob-num js-line-number" data-line-number="8"></td>
        <td id="LC8" class="blob-code blob-code-inner js-file-line"><span class="pl-c"># Like stdin and file inputs, each event is assumed to be one line of text.</span></td>
      </tr>
      <tr>
        <td id="L9" class="blob-num js-line-number" data-line-number="9"></td>
        <td id="LC9" class="blob-code blob-code-inner js-file-line"><span class="pl-c">#</span></td>
      </tr>
      <tr>
        <td id="L10" class="blob-num js-line-number" data-line-number="10"></td>
        <td id="LC10" class="blob-code blob-code-inner js-file-line"><span class="pl-c"># Can either accept connections from clients or connect to a server,</span></td>
      </tr>
      <tr>
        <td id="L11" class="blob-num js-line-number" data-line-number="11"></td>
        <td id="LC11" class="blob-code blob-code-inner js-file-line"><span class="pl-c"># depending on `mode`.</span></td>
      </tr>
      <tr>
        <td id="L12" class="blob-num js-line-number" data-line-number="12"></td>
        <td id="LC12" class="blob-code blob-code-inner js-file-line"><span class="pl-k">class</span> <span class="pl-en">LogStash::Inputs::Tcp<span class="pl-e"> &lt; LogStash::Inputs::Base</span></span></td>
      </tr>
      <tr>
        <td id="L13" class="blob-num js-line-number" data-line-number="13"></td>
        <td id="LC13" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">class</span> <span class="pl-en">Interrupted<span class="pl-e"> &lt; StandardError</span></span>; <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L14" class="blob-num js-line-number" data-line-number="14"></td>
        <td id="LC14" class="blob-code blob-code-inner js-file-line">  config_name <span class="pl-s"><span class="pl-pds">&quot;</span>tcp<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L15" class="blob-num js-line-number" data-line-number="15"></td>
        <td id="LC15" class="blob-code blob-code-inner js-file-line">  milestone <span class="pl-c1">2</span></td>
      </tr>
      <tr>
        <td id="L16" class="blob-num js-line-number" data-line-number="16"></td>
        <td id="LC16" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L17" class="blob-num js-line-number" data-line-number="17"></td>
        <td id="LC17" class="blob-code blob-code-inner js-file-line">  default <span class="pl-c1">:codec</span>, <span class="pl-s"><span class="pl-pds">&quot;</span>line<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L18" class="blob-num js-line-number" data-line-number="18"></td>
        <td id="LC18" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L19" class="blob-num js-line-number" data-line-number="19"></td>
        <td id="LC19" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># When mode is `server`, the address to listen on.</span></td>
      </tr>
      <tr>
        <td id="L20" class="blob-num js-line-number" data-line-number="20"></td>
        <td id="LC20" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># When mode is `client`, the address to connect to.</span></td>
      </tr>
      <tr>
        <td id="L21" class="blob-num js-line-number" data-line-number="21"></td>
        <td id="LC21" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:host</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:string</span>, <span class="pl-c1">:default</span> =&gt; <span class="pl-s"><span class="pl-pds">&quot;</span>0.0.0.0<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L22" class="blob-num js-line-number" data-line-number="22"></td>
        <td id="LC22" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L23" class="blob-num js-line-number" data-line-number="23"></td>
        <td id="LC23" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># When mode is `server`, the port to listen on.</span></td>
      </tr>
      <tr>
        <td id="L24" class="blob-num js-line-number" data-line-number="24"></td>
        <td id="LC24" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># When mode is `client`, the port to connect to.</span></td>
      </tr>
      <tr>
        <td id="L25" class="blob-num js-line-number" data-line-number="25"></td>
        <td id="LC25" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:port</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:number</span>, <span class="pl-c1">:required</span> =&gt; <span class="pl-c1">true</span></td>
      </tr>
      <tr>
        <td id="L26" class="blob-num js-line-number" data-line-number="26"></td>
        <td id="LC26" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L27" class="blob-num js-line-number" data-line-number="27"></td>
        <td id="LC27" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># The &#39;read&#39; timeout in seconds. If a particular tcp connection is idle for</span></td>
      </tr>
      <tr>
        <td id="L28" class="blob-num js-line-number" data-line-number="28"></td>
        <td id="LC28" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># more than this timeout period, we will assume it is dead and close it.</span></td>
      </tr>
      <tr>
        <td id="L29" class="blob-num js-line-number" data-line-number="29"></td>
        <td id="LC29" class="blob-code blob-code-inner js-file-line">  <span class="pl-c">#</span></td>
      </tr>
      <tr>
        <td id="L30" class="blob-num js-line-number" data-line-number="30"></td>
        <td id="LC30" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># If you never want to timeout, use -1.</span></td>
      </tr>
      <tr>
        <td id="L31" class="blob-num js-line-number" data-line-number="31"></td>
        <td id="LC31" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:data_timeout</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:number</span>, <span class="pl-c1">:default</span> =&gt; <span class="pl-k">-</span><span class="pl-c1">1</span></td>
      </tr>
      <tr>
        <td id="L32" class="blob-num js-line-number" data-line-number="32"></td>
        <td id="LC32" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L33" class="blob-num js-line-number" data-line-number="33"></td>
        <td id="LC33" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># Mode to operate in. `server` listens for client connections,</span></td>
      </tr>
      <tr>
        <td id="L34" class="blob-num js-line-number" data-line-number="34"></td>
        <td id="LC34" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># `client` connects to a server.</span></td>
      </tr>
      <tr>
        <td id="L35" class="blob-num js-line-number" data-line-number="35"></td>
        <td id="LC35" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:mode</span>, <span class="pl-c1">:validate</span> =&gt; [<span class="pl-s"><span class="pl-pds">&quot;</span>server<span class="pl-pds">&quot;</span></span>, <span class="pl-s"><span class="pl-pds">&quot;</span>client<span class="pl-pds">&quot;</span></span>], <span class="pl-c1">:default</span> =&gt; <span class="pl-s"><span class="pl-pds">&quot;</span>server<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L36" class="blob-num js-line-number" data-line-number="36"></td>
        <td id="LC36" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L37" class="blob-num js-line-number" data-line-number="37"></td>
        <td id="LC37" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># Enable SSL (must be set for other `ssl_` options to take effect).</span></td>
      </tr>
      <tr>
        <td id="L38" class="blob-num js-line-number" data-line-number="38"></td>
        <td id="LC38" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_enable</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:boolean</span>, <span class="pl-c1">:default</span> =&gt; <span class="pl-c1">false</span></td>
      </tr>
      <tr>
        <td id="L39" class="blob-num js-line-number" data-line-number="39"></td>
        <td id="LC39" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L40" class="blob-num js-line-number" data-line-number="40"></td>
        <td id="LC40" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># Verify the identity of the other end of the SSL connection against the CA.</span></td>
      </tr>
      <tr>
        <td id="L41" class="blob-num js-line-number" data-line-number="41"></td>
        <td id="LC41" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># For input, sets the field `sslsubject` to that of the client certificate.</span></td>
      </tr>
      <tr>
        <td id="L42" class="blob-num js-line-number" data-line-number="42"></td>
        <td id="LC42" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_verify</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:boolean</span>, <span class="pl-c1">:default</span> =&gt; <span class="pl-c1">false</span></td>
      </tr>
      <tr>
        <td id="L43" class="blob-num js-line-number" data-line-number="43"></td>
        <td id="LC43" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L44" class="blob-num js-line-number" data-line-number="44"></td>
        <td id="LC44" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># The SSL CA certificate, chainfile or CA path. The system CA path is automatically included.</span></td>
      </tr>
      <tr>
        <td id="L45" class="blob-num js-line-number" data-line-number="45"></td>
        <td id="LC45" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_cacert</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:path</span></td>
      </tr>
      <tr>
        <td id="L46" class="blob-num js-line-number" data-line-number="46"></td>
        <td id="LC46" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L47" class="blob-num js-line-number" data-line-number="47"></td>
        <td id="LC47" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># SSL certificate path</span></td>
      </tr>
      <tr>
        <td id="L48" class="blob-num js-line-number" data-line-number="48"></td>
        <td id="LC48" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_cert</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:path</span></td>
      </tr>
      <tr>
        <td id="L49" class="blob-num js-line-number" data-line-number="49"></td>
        <td id="LC49" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L50" class="blob-num js-line-number" data-line-number="50"></td>
        <td id="LC50" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># SSL key path</span></td>
      </tr>
      <tr>
        <td id="L51" class="blob-num js-line-number" data-line-number="51"></td>
        <td id="LC51" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_key</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:path</span></td>
      </tr>
      <tr>
        <td id="L52" class="blob-num js-line-number" data-line-number="52"></td>
        <td id="LC52" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L53" class="blob-num js-line-number" data-line-number="53"></td>
        <td id="LC53" class="blob-code blob-code-inner js-file-line">  <span class="pl-c"># SSL key passphrase</span></td>
      </tr>
      <tr>
        <td id="L54" class="blob-num js-line-number" data-line-number="54"></td>
        <td id="LC54" class="blob-code blob-code-inner js-file-line">  config <span class="pl-c1">:ssl_key_passphrase</span>, <span class="pl-c1">:validate</span> =&gt; <span class="pl-c1">:password</span>, <span class="pl-c1">:default</span> =&gt; <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L55" class="blob-num js-line-number" data-line-number="55"></td>
        <td id="LC55" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L56" class="blob-num js-line-number" data-line-number="56"></td>
        <td id="LC56" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">initialize</span>(<span class="pl-k">*</span><span class="pl-smi">args</span>)</td>
      </tr>
      <tr>
        <td id="L57" class="blob-num js-line-number" data-line-number="57"></td>
        <td id="LC57" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">super</span>(<span class="pl-k">*</span>args)</td>
      </tr>
      <tr>
        <td id="L58" class="blob-num js-line-number" data-line-number="58"></td>
        <td id="LC58" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def initialize</span></td>
      </tr>
      <tr>
        <td id="L59" class="blob-num js-line-number" data-line-number="59"></td>
        <td id="LC59" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L60" class="blob-num js-line-number" data-line-number="60"></td>
        <td id="LC60" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">public</span></td>
      </tr>
      <tr>
        <td id="L61" class="blob-num js-line-number" data-line-number="61"></td>
        <td id="LC61" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">register</span></td>
      </tr>
      <tr>
        <td id="L62" class="blob-num js-line-number" data-line-number="62"></td>
        <td id="LC62" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>socket<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L63" class="blob-num js-line-number" data-line-number="63"></td>
        <td id="LC63" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>timeout<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L64" class="blob-num js-line-number" data-line-number="64"></td>
        <td id="LC64" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">require</span> <span class="pl-s"><span class="pl-pds">&quot;</span>openssl<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L65" class="blob-num js-line-number" data-line-number="65"></td>
        <td id="LC65" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L66" class="blob-num js-line-number" data-line-number="66"></td>
        <td id="LC66" class="blob-code blob-code-inner js-file-line">    <span class="pl-c"># monkey patch TCPSocket and SSLSocket to include socket peer</span></td>
      </tr>
      <tr>
        <td id="L67" class="blob-num js-line-number" data-line-number="67"></td>
        <td id="LC67" class="blob-code blob-code-inner js-file-line">    <span class="pl-c1">TCPSocket</span>.module_eval{<span class="pl-k">include</span> ::<span class="pl-c1">LogStash</span>::<span class="pl-c1">Util</span>::<span class="pl-c1">SocketPeer</span>}</td>
      </tr>
      <tr>
        <td id="L68" class="blob-num js-line-number" data-line-number="68"></td>
        <td id="LC68" class="blob-code blob-code-inner js-file-line">    <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLSocket</span>.module_eval{<span class="pl-k">include</span> ::<span class="pl-c1">LogStash</span>::<span class="pl-c1">Util</span>::<span class="pl-c1">SocketPeer</span>}</td>
      </tr>
      <tr>
        <td id="L69" class="blob-num js-line-number" data-line-number="69"></td>
        <td id="LC69" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L70" class="blob-num js-line-number" data-line-number="70"></td>
        <td id="LC70" class="blob-code blob-code-inner js-file-line">    fix_streaming_codecs</td>
      </tr>
      <tr>
        <td id="L71" class="blob-num js-line-number" data-line-number="71"></td>
        <td id="LC71" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L72" class="blob-num js-line-number" data-line-number="72"></td>
        <td id="LC72" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">if</span> <span class="pl-smi">@ssl_enable</span></td>
      </tr>
      <tr>
        <td id="L73" class="blob-num js-line-number" data-line-number="73"></td>
        <td id="LC73" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@ssl_context</span> <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLContext</span>.<span class="pl-k">new</span></td>
      </tr>
      <tr>
        <td id="L74" class="blob-num js-line-number" data-line-number="74"></td>
        <td id="LC74" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@ssl_context</span>.cert <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">X509</span>::<span class="pl-c1">Certificate</span>.<span class="pl-k">new</span>(<span class="pl-c1">File</span>.read(<span class="pl-smi">@ssl_cert</span>))</td>
      </tr>
      <tr>
        <td id="L75" class="blob-num js-line-number" data-line-number="75"></td>
        <td id="LC75" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@ssl_context</span>.key <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">PKey</span>::<span class="pl-c1">RSA</span>.<span class="pl-k">new</span>(<span class="pl-c1">File</span>.read(<span class="pl-smi">@ssl_key</span>),<span class="pl-smi">@ssl_key_passphrase</span>)</td>
      </tr>
      <tr>
        <td id="L76" class="blob-num js-line-number" data-line-number="76"></td>
        <td id="LC76" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">if</span> <span class="pl-smi">@ssl_verify</span></td>
      </tr>
      <tr>
        <td id="L77" class="blob-num js-line-number" data-line-number="77"></td>
        <td id="LC77" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@cert_store</span> <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">X509</span>::<span class="pl-c1">Store</span>.<span class="pl-k">new</span></td>
      </tr>
      <tr>
        <td id="L78" class="blob-num js-line-number" data-line-number="78"></td>
        <td id="LC78" class="blob-code blob-code-inner js-file-line">        <span class="pl-c"># Load the system default certificate path to the store</span></td>
      </tr>
      <tr>
        <td id="L79" class="blob-num js-line-number" data-line-number="79"></td>
        <td id="LC79" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@cert_store</span>.set_default_paths</td>
      </tr>
      <tr>
        <td id="L80" class="blob-num js-line-number" data-line-number="80"></td>
        <td id="LC80" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">if</span> <span class="pl-c1">File</span>.directory?(<span class="pl-smi">@ssl_cacert</span>)</td>
      </tr>
      <tr>
        <td id="L81" class="blob-num js-line-number" data-line-number="81"></td>
        <td id="LC81" class="blob-code blob-code-inner js-file-line">          <span class="pl-smi">@cert_store</span>.add_path(<span class="pl-smi">@ssl_cacert</span>)</td>
      </tr>
      <tr>
        <td id="L82" class="blob-num js-line-number" data-line-number="82"></td>
        <td id="LC82" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">else</span></td>
      </tr>
      <tr>
        <td id="L83" class="blob-num js-line-number" data-line-number="83"></td>
        <td id="LC83" class="blob-code blob-code-inner js-file-line">          <span class="pl-smi">@cert_store</span>.add_file(<span class="pl-smi">@ssl_cacert</span>)</td>
      </tr>
      <tr>
        <td id="L84" class="blob-num js-line-number" data-line-number="84"></td>
        <td id="LC84" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L85" class="blob-num js-line-number" data-line-number="85"></td>
        <td id="LC85" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@ssl_context</span>.cert_store <span class="pl-k">=</span> <span class="pl-smi">@cert_store</span></td>
      </tr>
      <tr>
        <td id="L86" class="blob-num js-line-number" data-line-number="86"></td>
        <td id="LC86" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@ssl_context</span>.verify_mode <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">VERIFY_PEER</span><span class="pl-k">|</span><span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">VERIFY_FAIL_IF_NO_PEER_CERT</span></td>
      </tr>
      <tr>
        <td id="L87" class="blob-num js-line-number" data-line-number="87"></td>
        <td id="LC87" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L88" class="blob-num js-line-number" data-line-number="88"></td>
        <td id="LC88" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span> <span class="pl-c"># @ssl_enable</span></td>
      </tr>
      <tr>
        <td id="L89" class="blob-num js-line-number" data-line-number="89"></td>
        <td id="LC89" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L90" class="blob-num js-line-number" data-line-number="90"></td>
        <td id="LC90" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">if</span> server?</td>
      </tr>
      <tr>
        <td id="L91" class="blob-num js-line-number" data-line-number="91"></td>
        <td id="LC91" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@logger</span>.info(<span class="pl-s"><span class="pl-pds">&quot;</span>Starting tcp input listener<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:address</span> =&gt; <span class="pl-s"><span class="pl-pds">&quot;</span><span class="pl-pse">#{</span><span class="pl-s1"><span class="pl-smi">@host</span></span><span class="pl-pse"><span class="pl-s1">}</span></span>:<span class="pl-pse">#{</span><span class="pl-s1"><span class="pl-smi">@port</span></span><span class="pl-pse"><span class="pl-s1">}</span></span><span class="pl-pds">&quot;</span></span>)</td>
      </tr>
      <tr>
        <td id="L92" class="blob-num js-line-number" data-line-number="92"></td>
        <td id="LC92" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">begin</span></td>
      </tr>
      <tr>
        <td id="L93" class="blob-num js-line-number" data-line-number="93"></td>
        <td id="LC93" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@server_socket</span> <span class="pl-k">=</span> <span class="pl-c1">TCPServer</span>.<span class="pl-k">new</span>(<span class="pl-smi">@host</span>, <span class="pl-smi">@port</span>)</td>
      </tr>
      <tr>
        <td id="L94" class="blob-num js-line-number" data-line-number="94"></td>
        <td id="LC94" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">rescue</span> <span class="pl-c1">Errno</span>::<span class="pl-c1">EADDRINUSE</span></td>
      </tr>
      <tr>
        <td id="L95" class="blob-num js-line-number" data-line-number="95"></td>
        <td id="LC95" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@logger</span>.error(<span class="pl-s"><span class="pl-pds">&quot;</span>Could not start TCP server: Address in use<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:host</span> =&gt; <span class="pl-smi">@host</span>, <span class="pl-c1">:port</span> =&gt; <span class="pl-smi">@port</span>)</td>
      </tr>
      <tr>
        <td id="L96" class="blob-num js-line-number" data-line-number="96"></td>
        <td id="LC96" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">raise</span></td>
      </tr>
      <tr>
        <td id="L97" class="blob-num js-line-number" data-line-number="97"></td>
        <td id="LC97" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L98" class="blob-num js-line-number" data-line-number="98"></td>
        <td id="LC98" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">if</span> <span class="pl-smi">@ssl_enable</span></td>
      </tr>
      <tr>
        <td id="L99" class="blob-num js-line-number" data-line-number="99"></td>
        <td id="LC99" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@server_socket</span> <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLServer</span>.<span class="pl-k">new</span>(<span class="pl-smi">@server_socket</span>, <span class="pl-smi">@ssl_context</span>)</td>
      </tr>
      <tr>
        <td id="L100" class="blob-num js-line-number" data-line-number="100"></td>
        <td id="LC100" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span> <span class="pl-c"># @ssl_enable</span></td>
      </tr>
      <tr>
        <td id="L101" class="blob-num js-line-number" data-line-number="101"></td>
        <td id="LC101" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L102" class="blob-num js-line-number" data-line-number="102"></td>
        <td id="LC102" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def register</span></td>
      </tr>
      <tr>
        <td id="L103" class="blob-num js-line-number" data-line-number="103"></td>
        <td id="LC103" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L104" class="blob-num js-line-number" data-line-number="104"></td>
        <td id="LC104" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">private</span></td>
      </tr>
      <tr>
        <td id="L105" class="blob-num js-line-number" data-line-number="105"></td>
        <td id="LC105" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">handle_socket</span>(<span class="pl-smi">socket</span>, <span class="pl-smi">client_address</span>, <span class="pl-smi">output_queue</span>, <span class="pl-smi">codec</span>)</td>
      </tr>
      <tr>
        <td id="L106" class="blob-num js-line-number" data-line-number="106"></td>
        <td id="LC106" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">while</span> <span class="pl-c1">true</span></td>
      </tr>
      <tr>
        <td id="L107" class="blob-num js-line-number" data-line-number="107"></td>
        <td id="LC107" class="blob-code blob-code-inner js-file-line">      buf <span class="pl-k">=</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L108" class="blob-num js-line-number" data-line-number="108"></td>
        <td id="LC108" class="blob-code blob-code-inner js-file-line">      <span class="pl-c"># NOTE(petef): the timeout only hits after the line is read or socket dies</span></td>
      </tr>
      <tr>
        <td id="L109" class="blob-num js-line-number" data-line-number="109"></td>
        <td id="LC109" class="blob-code blob-code-inner js-file-line">      <span class="pl-c"># TODO(sissel): Why do we have a timeout here? What&#39;s the point?</span></td>
      </tr>
      <tr>
        <td id="L110" class="blob-num js-line-number" data-line-number="110"></td>
        <td id="LC110" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">if</span> <span class="pl-smi">@data_timeout</span> <span class="pl-k">==</span> <span class="pl-k">-</span><span class="pl-c1">1</span></td>
      </tr>
      <tr>
        <td id="L111" class="blob-num js-line-number" data-line-number="111"></td>
        <td id="LC111" class="blob-code blob-code-inner js-file-line">        buf <span class="pl-k">=</span> read(socket)</td>
      </tr>
      <tr>
        <td id="L112" class="blob-num js-line-number" data-line-number="112"></td>
        <td id="LC112" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">else</span></td>
      </tr>
      <tr>
        <td id="L113" class="blob-num js-line-number" data-line-number="113"></td>
        <td id="LC113" class="blob-code blob-code-inner js-file-line">        <span class="pl-c1">Timeout</span>::timeout(<span class="pl-smi">@data_timeout</span>) <span class="pl-k">do</span></td>
      </tr>
      <tr>
        <td id="L114" class="blob-num js-line-number" data-line-number="114"></td>
        <td id="LC114" class="blob-code blob-code-inner js-file-line">          buf <span class="pl-k">=</span> read(socket)</td>
      </tr>
      <tr>
        <td id="L115" class="blob-num js-line-number" data-line-number="115"></td>
        <td id="LC115" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L116" class="blob-num js-line-number" data-line-number="116"></td>
        <td id="LC116" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L117" class="blob-num js-line-number" data-line-number="117"></td>
        <td id="LC117" class="blob-code blob-code-inner js-file-line">      codec.decode(buf) <span class="pl-k">do </span>|<span class="pl-smi">event</span>|</td>
      </tr>
      <tr>
        <td id="L118" class="blob-num js-line-number" data-line-number="118"></td>
        <td id="LC118" class="blob-code blob-code-inner js-file-line">        event[<span class="pl-s"><span class="pl-pds">&quot;</span>host<span class="pl-pds">&quot;</span></span>] <span class="pl-k">||=</span> client_address</td>
      </tr>
      <tr>
        <td id="L119" class="blob-num js-line-number" data-line-number="119"></td>
        <td id="LC119" class="blob-code blob-code-inner js-file-line">        event[<span class="pl-s"><span class="pl-pds">&quot;</span>sslsubject<span class="pl-pds">&quot;</span></span>] <span class="pl-k">||=</span> socket.peer_cert.subject <span class="pl-k">if</span> <span class="pl-smi">@ssl_enable</span> <span class="pl-k">&amp;&amp;</span> <span class="pl-smi">@ssl_verify</span></td>
      </tr>
      <tr>
        <td id="L120" class="blob-num js-line-number" data-line-number="120"></td>
        <td id="LC120" class="blob-code blob-code-inner js-file-line">        decorate(event)</td>
      </tr>
      <tr>
        <td id="L121" class="blob-num js-line-number" data-line-number="121"></td>
        <td id="LC121" class="blob-code blob-code-inner js-file-line">        output_queue <span class="pl-k">&lt;&lt;</span> event</td>
      </tr>
      <tr>
        <td id="L122" class="blob-num js-line-number" data-line-number="122"></td>
        <td id="LC122" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L123" class="blob-num js-line-number" data-line-number="123"></td>
        <td id="LC123" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span> <span class="pl-c"># loop</span></td>
      </tr>
      <tr>
        <td id="L124" class="blob-num js-line-number" data-line-number="124"></td>
        <td id="LC124" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">rescue</span> <span class="pl-c1">EOFError</span></td>
      </tr>
      <tr>
        <td id="L125" class="blob-num js-line-number" data-line-number="125"></td>
        <td id="LC125" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@logger</span>.debug? <span class="pl-k">&amp;&amp;</span> <span class="pl-smi">@logger</span>.debug(<span class="pl-s"><span class="pl-pds">&quot;</span>Connection closed<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:client</span> =&gt; socket.peer)</td>
      </tr>
      <tr>
        <td id="L126" class="blob-num js-line-number" data-line-number="126"></td>
        <td id="LC126" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">rescue</span> <span class="pl-c1">Errno</span>::<span class="pl-c1">ECONNRESET</span></td>
      </tr>
      <tr>
        <td id="L127" class="blob-num js-line-number" data-line-number="127"></td>
        <td id="LC127" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@logger</span>.debug? <span class="pl-k">&amp;&amp;</span> <span class="pl-smi">@logger</span>.debug(<span class="pl-s"><span class="pl-pds">&quot;</span>Connection reset by peer<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:client</span> =&gt; socket.peer)</td>
      </tr>
      <tr>
        <td id="L128" class="blob-num js-line-number" data-line-number="128"></td>
        <td id="LC128" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">rescue</span> =&gt; e</td>
      </tr>
      <tr>
        <td id="L129" class="blob-num js-line-number" data-line-number="129"></td>
        <td id="LC129" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@logger</span>.error(<span class="pl-s"><span class="pl-pds">&quot;</span>An error occurred. Closing connection<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:client</span> =&gt; socket.peer, <span class="pl-c1">:exception</span> =&gt; e, <span class="pl-c1">:backtrace</span> =&gt; e.backtrace)</td>
      </tr>
      <tr>
        <td id="L130" class="blob-num js-line-number" data-line-number="130"></td>
        <td id="LC130" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">ensure</span></td>
      </tr>
      <tr>
        <td id="L131" class="blob-num js-line-number" data-line-number="131"></td>
        <td id="LC131" class="blob-code blob-code-inner js-file-line">    socket.close <span class="pl-k">rescue</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L132" class="blob-num js-line-number" data-line-number="132"></td>
        <td id="LC132" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L133" class="blob-num js-line-number" data-line-number="133"></td>
        <td id="LC133" class="blob-code blob-code-inner js-file-line">    codec.respond_to?(<span class="pl-c1">:flush</span>) <span class="pl-k">&amp;&amp;</span> codec.flush <span class="pl-k">do </span>|<span class="pl-smi">event</span>|</td>
      </tr>
      <tr>
        <td id="L134" class="blob-num js-line-number" data-line-number="134"></td>
        <td id="LC134" class="blob-code blob-code-inner js-file-line">      event[<span class="pl-s"><span class="pl-pds">&quot;</span>host<span class="pl-pds">&quot;</span></span>] <span class="pl-k">||=</span> client_address</td>
      </tr>
      <tr>
        <td id="L135" class="blob-num js-line-number" data-line-number="135"></td>
        <td id="LC135" class="blob-code blob-code-inner js-file-line">      event[<span class="pl-s"><span class="pl-pds">&quot;</span>sslsubject<span class="pl-pds">&quot;</span></span>] <span class="pl-k">||=</span> socket.peer_cert.subject <span class="pl-k">if</span> <span class="pl-smi">@ssl_enable</span> <span class="pl-k">&amp;&amp;</span> <span class="pl-smi">@ssl_verify</span></td>
      </tr>
      <tr>
        <td id="L136" class="blob-num js-line-number" data-line-number="136"></td>
        <td id="LC136" class="blob-code blob-code-inner js-file-line">      decorate(event)</td>
      </tr>
      <tr>
        <td id="L137" class="blob-num js-line-number" data-line-number="137"></td>
        <td id="LC137" class="blob-code blob-code-inner js-file-line">      output_queue <span class="pl-k">&lt;&lt;</span> event</td>
      </tr>
      <tr>
        <td id="L138" class="blob-num js-line-number" data-line-number="138"></td>
        <td id="LC138" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L139" class="blob-num js-line-number" data-line-number="139"></td>
        <td id="LC139" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L140" class="blob-num js-line-number" data-line-number="140"></td>
        <td id="LC140" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L141" class="blob-num js-line-number" data-line-number="141"></td>
        <td id="LC141" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">private</span></td>
      </tr>
      <tr>
        <td id="L142" class="blob-num js-line-number" data-line-number="142"></td>
        <td id="LC142" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">client_thread</span>(<span class="pl-smi">output_queue</span>, <span class="pl-smi">socket</span>)</td>
      </tr>
      <tr>
        <td id="L143" class="blob-num js-line-number" data-line-number="143"></td>
        <td id="LC143" class="blob-code blob-code-inner js-file-line">    <span class="pl-c1">Thread</span>.<span class="pl-k">new</span>(output_queue, socket) <span class="pl-k">do </span>|<span class="pl-smi">q</span>, <span class="pl-smi">s</span>|</td>
      </tr>
      <tr>
        <td id="L144" class="blob-num js-line-number" data-line-number="144"></td>
        <td id="LC144" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">begin</span></td>
      </tr>
      <tr>
        <td id="L145" class="blob-num js-line-number" data-line-number="145"></td>
        <td id="LC145" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@logger</span>.debug? <span class="pl-k">&amp;&amp;</span> <span class="pl-smi">@logger</span>.debug(<span class="pl-s"><span class="pl-pds">&quot;</span>Accepted connection<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:client</span> =&gt; s.peer, <span class="pl-c1">:server</span> =&gt; <span class="pl-s"><span class="pl-pds">&quot;</span><span class="pl-pse">#{</span><span class="pl-s1"><span class="pl-smi">@host</span></span><span class="pl-pse"><span class="pl-s1">}</span></span>:<span class="pl-pse">#{</span><span class="pl-s1"><span class="pl-smi">@port</span></span><span class="pl-pse"><span class="pl-s1">}</span></span><span class="pl-pds">&quot;</span></span>)</td>
      </tr>
      <tr>
        <td id="L146" class="blob-num js-line-number" data-line-number="146"></td>
        <td id="LC146" class="blob-code blob-code-inner js-file-line">        handle_socket(s, s.peer, q, <span class="pl-smi">@codec</span>.clone)</td>
      </tr>
      <tr>
        <td id="L147" class="blob-num js-line-number" data-line-number="147"></td>
        <td id="LC147" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">rescue</span> <span class="pl-c1">Interrupted</span></td>
      </tr>
      <tr>
        <td id="L148" class="blob-num js-line-number" data-line-number="148"></td>
        <td id="LC148" class="blob-code blob-code-inner js-file-line">        s.close <span class="pl-k">rescue</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L149" class="blob-num js-line-number" data-line-number="149"></td>
        <td id="LC149" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">ensure</span></td>
      </tr>
      <tr>
        <td id="L150" class="blob-num js-line-number" data-line-number="150"></td>
        <td id="LC150" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@client_threads_lock</span>.synchronize{<span class="pl-smi">@client_threads</span>.delete(<span class="pl-c1">Thread</span>.current)}</td>
      </tr>
      <tr>
        <td id="L151" class="blob-num js-line-number" data-line-number="151"></td>
        <td id="LC151" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L152" class="blob-num js-line-number" data-line-number="152"></td>
        <td id="LC152" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L153" class="blob-num js-line-number" data-line-number="153"></td>
        <td id="LC153" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L154" class="blob-num js-line-number" data-line-number="154"></td>
        <td id="LC154" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L155" class="blob-num js-line-number" data-line-number="155"></td>
        <td id="LC155" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">private</span></td>
      </tr>
      <tr>
        <td id="L156" class="blob-num js-line-number" data-line-number="156"></td>
        <td id="LC156" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">server?</span></td>
      </tr>
      <tr>
        <td id="L157" class="blob-num js-line-number" data-line-number="157"></td>
        <td id="LC157" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@mode</span> <span class="pl-k">==</span> <span class="pl-s"><span class="pl-pds">&quot;</span>server<span class="pl-pds">&quot;</span></span></td>
      </tr>
      <tr>
        <td id="L158" class="blob-num js-line-number" data-line-number="158"></td>
        <td id="LC158" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def server?</span></td>
      </tr>
      <tr>
        <td id="L159" class="blob-num js-line-number" data-line-number="159"></td>
        <td id="LC159" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L160" class="blob-num js-line-number" data-line-number="160"></td>
        <td id="LC160" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">private</span></td>
      </tr>
      <tr>
        <td id="L161" class="blob-num js-line-number" data-line-number="161"></td>
        <td id="LC161" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">read</span>(<span class="pl-smi">socket</span>)</td>
      </tr>
      <tr>
        <td id="L162" class="blob-num js-line-number" data-line-number="162"></td>
        <td id="LC162" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">return</span> socket.sysread(<span class="pl-c1">16384</span>)</td>
      </tr>
      <tr>
        <td id="L163" class="blob-num js-line-number" data-line-number="163"></td>
        <td id="LC163" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def readline</span></td>
      </tr>
      <tr>
        <td id="L164" class="blob-num js-line-number" data-line-number="164"></td>
        <td id="LC164" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L165" class="blob-num js-line-number" data-line-number="165"></td>
        <td id="LC165" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">public</span></td>
      </tr>
      <tr>
        <td id="L166" class="blob-num js-line-number" data-line-number="166"></td>
        <td id="LC166" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">run</span>(<span class="pl-smi">output_queue</span>)</td>
      </tr>
      <tr>
        <td id="L167" class="blob-num js-line-number" data-line-number="167"></td>
        <td id="LC167" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">if</span> server?</td>
      </tr>
      <tr>
        <td id="L168" class="blob-num js-line-number" data-line-number="168"></td>
        <td id="LC168" class="blob-code blob-code-inner js-file-line">      run_server(output_queue)</td>
      </tr>
      <tr>
        <td id="L169" class="blob-num js-line-number" data-line-number="169"></td>
        <td id="LC169" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">else</span></td>
      </tr>
      <tr>
        <td id="L170" class="blob-num js-line-number" data-line-number="170"></td>
        <td id="LC170" class="blob-code blob-code-inner js-file-line">      run_client(output_queue)</td>
      </tr>
      <tr>
        <td id="L171" class="blob-num js-line-number" data-line-number="171"></td>
        <td id="LC171" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L172" class="blob-num js-line-number" data-line-number="172"></td>
        <td id="LC172" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def run</span></td>
      </tr>
      <tr>
        <td id="L173" class="blob-num js-line-number" data-line-number="173"></td>
        <td id="LC173" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L174" class="blob-num js-line-number" data-line-number="174"></td>
        <td id="LC174" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">run_server</span>(<span class="pl-smi">output_queue</span>)</td>
      </tr>
      <tr>
        <td id="L175" class="blob-num js-line-number" data-line-number="175"></td>
        <td id="LC175" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@thread</span> <span class="pl-k">=</span> <span class="pl-c1">Thread</span>.current</td>
      </tr>
      <tr>
        <td id="L176" class="blob-num js-line-number" data-line-number="176"></td>
        <td id="LC176" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@client_threads</span> <span class="pl-k">=</span> []</td>
      </tr>
      <tr>
        <td id="L177" class="blob-num js-line-number" data-line-number="177"></td>
        <td id="LC177" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@client_threads_lock</span> <span class="pl-k">=</span> <span class="pl-c1">Mutex</span>.<span class="pl-k">new</span></td>
      </tr>
      <tr>
        <td id="L178" class="blob-num js-line-number" data-line-number="178"></td>
        <td id="LC178" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L179" class="blob-num js-line-number" data-line-number="179"></td>
        <td id="LC179" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">while</span> <span class="pl-c1">true</span></td>
      </tr>
      <tr>
        <td id="L180" class="blob-num js-line-number" data-line-number="180"></td>
        <td id="LC180" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">begin</span></td>
      </tr>
      <tr>
        <td id="L181" class="blob-num js-line-number" data-line-number="181"></td>
        <td id="LC181" class="blob-code blob-code-inner js-file-line">        socket <span class="pl-k">=</span> <span class="pl-smi">@server_socket</span>.accept</td>
      </tr>
      <tr>
        <td id="L182" class="blob-num js-line-number" data-line-number="182"></td>
        <td id="LC182" class="blob-code blob-code-inner js-file-line">        <span class="pl-c"># start a new thread for each connection.</span></td>
      </tr>
      <tr>
        <td id="L183" class="blob-num js-line-number" data-line-number="183"></td>
        <td id="LC183" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@client_threads_lock</span>.synchronize{<span class="pl-smi">@client_threads</span> <span class="pl-k">&lt;&lt;</span> client_thread(output_queue, socket)}</td>
      </tr>
      <tr>
        <td id="L184" class="blob-num js-line-number" data-line-number="184"></td>
        <td id="LC184" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">rescue</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLError</span> =&gt; ssle</td>
      </tr>
      <tr>
        <td id="L185" class="blob-num js-line-number" data-line-number="185"></td>
        <td id="LC185" class="blob-code blob-code-inner js-file-line">        <span class="pl-c"># NOTE(mrichar1): This doesn&#39;t return a useful error message for some reason</span></td>
      </tr>
      <tr>
        <td id="L186" class="blob-num js-line-number" data-line-number="186"></td>
        <td id="LC186" class="blob-code blob-code-inner js-file-line">        <span class="pl-smi">@logger</span>.error(<span class="pl-s"><span class="pl-pds">&quot;</span>SSL Error<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:exception</span> =&gt; ssle, <span class="pl-c1">:backtrace</span> =&gt; ssle.backtrace)</td>
      </tr>
      <tr>
        <td id="L187" class="blob-num js-line-number" data-line-number="187"></td>
        <td id="LC187" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">rescue</span> <span class="pl-c1">IOError</span>, <span class="pl-c1">LogStash</span>::<span class="pl-c1">ShutdownSignal</span></td>
      </tr>
      <tr>
        <td id="L188" class="blob-num js-line-number" data-line-number="188"></td>
        <td id="LC188" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">if</span> <span class="pl-smi">@interrupted</span></td>
      </tr>
      <tr>
        <td id="L189" class="blob-num js-line-number" data-line-number="189"></td>
        <td id="LC189" class="blob-code blob-code-inner js-file-line">          <span class="pl-smi">@server_socket</span>.close <span class="pl-k">rescue</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L190" class="blob-num js-line-number" data-line-number="190"></td>
        <td id="LC190" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L191" class="blob-num js-line-number" data-line-number="191"></td>
        <td id="LC191" class="blob-code blob-code-inner js-file-line">          threads <span class="pl-k">=</span> <span class="pl-smi">@client_threads_lock</span>.synchronize{<span class="pl-smi">@client_threads</span>.dup}</td>
      </tr>
      <tr>
        <td id="L192" class="blob-num js-line-number" data-line-number="192"></td>
        <td id="LC192" class="blob-code blob-code-inner js-file-line">          threads.each <span class="pl-k">do </span>|<span class="pl-smi">thread</span>|</td>
      </tr>
      <tr>
        <td id="L193" class="blob-num js-line-number" data-line-number="193"></td>
        <td id="LC193" class="blob-code blob-code-inner js-file-line">            thread.<span class="pl-k">raise</span>(<span class="pl-c1">LogStash</span>::<span class="pl-c1">ShutdownSignal</span>) <span class="pl-k">if</span> thread.alive?</td>
      </tr>
      <tr>
        <td id="L194" class="blob-num js-line-number" data-line-number="194"></td>
        <td id="LC194" class="blob-code blob-code-inner js-file-line">          <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L195" class="blob-num js-line-number" data-line-number="195"></td>
        <td id="LC195" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L196" class="blob-num js-line-number" data-line-number="196"></td>
        <td id="LC196" class="blob-code blob-code-inner js-file-line">          <span class="pl-c"># intended shutdown, get out of the loop</span></td>
      </tr>
      <tr>
        <td id="L197" class="blob-num js-line-number" data-line-number="197"></td>
        <td id="LC197" class="blob-code blob-code-inner js-file-line">          <span class="pl-k">break</span></td>
      </tr>
      <tr>
        <td id="L198" class="blob-num js-line-number" data-line-number="198"></td>
        <td id="LC198" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">else</span></td>
      </tr>
      <tr>
        <td id="L199" class="blob-num js-line-number" data-line-number="199"></td>
        <td id="LC199" class="blob-code blob-code-inner js-file-line">          <span class="pl-c"># it was a genuine IOError, propagate it up</span></td>
      </tr>
      <tr>
        <td id="L200" class="blob-num js-line-number" data-line-number="200"></td>
        <td id="LC200" class="blob-code blob-code-inner js-file-line">          <span class="pl-k">raise</span></td>
      </tr>
      <tr>
        <td id="L201" class="blob-num js-line-number" data-line-number="201"></td>
        <td id="LC201" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L202" class="blob-num js-line-number" data-line-number="202"></td>
        <td id="LC202" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L203" class="blob-num js-line-number" data-line-number="203"></td>
        <td id="LC203" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span> <span class="pl-c"># loop</span></td>
      </tr>
      <tr>
        <td id="L204" class="blob-num js-line-number" data-line-number="204"></td>
        <td id="LC204" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">rescue</span> <span class="pl-c1">LogStash</span>::<span class="pl-c1">ShutdownSignal</span></td>
      </tr>
      <tr>
        <td id="L205" class="blob-num js-line-number" data-line-number="205"></td>
        <td id="LC205" class="blob-code blob-code-inner js-file-line">    <span class="pl-c"># nothing to do</span></td>
      </tr>
      <tr>
        <td id="L206" class="blob-num js-line-number" data-line-number="206"></td>
        <td id="LC206" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">ensure</span></td>
      </tr>
      <tr>
        <td id="L207" class="blob-num js-line-number" data-line-number="207"></td>
        <td id="LC207" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@server_socket</span>.close <span class="pl-k">rescue</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L208" class="blob-num js-line-number" data-line-number="208"></td>
        <td id="LC208" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def run_server</span></td>
      </tr>
      <tr>
        <td id="L209" class="blob-num js-line-number" data-line-number="209"></td>
        <td id="LC209" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L210" class="blob-num js-line-number" data-line-number="210"></td>
        <td id="LC210" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">run_client</span>(<span class="pl-smi">output_queue</span>)</td>
      </tr>
      <tr>
        <td id="L211" class="blob-num js-line-number" data-line-number="211"></td>
        <td id="LC211" class="blob-code blob-code-inner js-file-line">    <span class="pl-smi">@thread</span> <span class="pl-k">=</span> <span class="pl-c1">Thread</span>.current</td>
      </tr>
      <tr>
        <td id="L212" class="blob-num js-line-number" data-line-number="212"></td>
        <td id="LC212" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">while</span> <span class="pl-c1">true</span></td>
      </tr>
      <tr>
        <td id="L213" class="blob-num js-line-number" data-line-number="213"></td>
        <td id="LC213" class="blob-code blob-code-inner js-file-line">      client_socket <span class="pl-k">=</span> <span class="pl-c1">TCPSocket</span>.<span class="pl-k">new</span>(<span class="pl-smi">@host</span>, <span class="pl-smi">@port</span>)</td>
      </tr>
      <tr>
        <td id="L214" class="blob-num js-line-number" data-line-number="214"></td>
        <td id="LC214" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">if</span> <span class="pl-smi">@ssl_enable</span></td>
      </tr>
      <tr>
        <td id="L215" class="blob-num js-line-number" data-line-number="215"></td>
        <td id="LC215" class="blob-code blob-code-inner js-file-line">        client_socket <span class="pl-k">=</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLSocket</span>.<span class="pl-k">new</span>(client_socket, <span class="pl-smi">@ssl_context</span>)</td>
      </tr>
      <tr>
        <td id="L216" class="blob-num js-line-number" data-line-number="216"></td>
        <td id="LC216" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">begin</span></td>
      </tr>
      <tr>
        <td id="L217" class="blob-num js-line-number" data-line-number="217"></td>
        <td id="LC217" class="blob-code blob-code-inner js-file-line">          client_socket.connect</td>
      </tr>
      <tr>
        <td id="L218" class="blob-num js-line-number" data-line-number="218"></td>
        <td id="LC218" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">rescue</span> <span class="pl-c1">OpenSSL</span>::<span class="pl-c1">SSL</span>::<span class="pl-c1">SSLError</span> =&gt; ssle</td>
      </tr>
      <tr>
        <td id="L219" class="blob-num js-line-number" data-line-number="219"></td>
        <td id="LC219" class="blob-code blob-code-inner js-file-line">          <span class="pl-smi">@logger</span>.error(<span class="pl-s"><span class="pl-pds">&quot;</span>SSL Error<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:exception</span> =&gt; ssle, <span class="pl-c1">:backtrace</span> =&gt; ssle.backtrace)</td>
      </tr>
      <tr>
        <td id="L220" class="blob-num js-line-number" data-line-number="220"></td>
        <td id="LC220" class="blob-code blob-code-inner js-file-line">          <span class="pl-c"># NOTE(mrichar1): Hack to prevent hammering peer</span></td>
      </tr>
      <tr>
        <td id="L221" class="blob-num js-line-number" data-line-number="221"></td>
        <td id="LC221" class="blob-code blob-code-inner js-file-line">          sleep(<span class="pl-c1">5</span>)</td>
      </tr>
      <tr>
        <td id="L222" class="blob-num js-line-number" data-line-number="222"></td>
        <td id="LC222" class="blob-code blob-code-inner js-file-line">          <span class="pl-k">next</span></td>
      </tr>
      <tr>
        <td id="L223" class="blob-num js-line-number" data-line-number="223"></td>
        <td id="LC223" class="blob-code blob-code-inner js-file-line">        <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L224" class="blob-num js-line-number" data-line-number="224"></td>
        <td id="LC224" class="blob-code blob-code-inner js-file-line">      <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L225" class="blob-num js-line-number" data-line-number="225"></td>
        <td id="LC225" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@logger</span>.debug(<span class="pl-s"><span class="pl-pds">&quot;</span>Opened connection<span class="pl-pds">&quot;</span></span>, <span class="pl-c1">:client</span> =&gt; <span class="pl-s"><span class="pl-pds">&quot;</span><span class="pl-pse">#{</span><span class="pl-s1">client_socket.peer</span><span class="pl-pse"><span class="pl-s1">}</span></span><span class="pl-pds">&quot;</span></span>)</td>
      </tr>
      <tr>
        <td id="L226" class="blob-num js-line-number" data-line-number="226"></td>
        <td id="LC226" class="blob-code blob-code-inner js-file-line">      handle_socket(client_socket, client_socket.peer, output_queue, <span class="pl-smi">@codec</span>.clone)</td>
      </tr>
      <tr>
        <td id="L227" class="blob-num js-line-number" data-line-number="227"></td>
        <td id="LC227" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span> <span class="pl-c"># loop</span></td>
      </tr>
      <tr>
        <td id="L228" class="blob-num js-line-number" data-line-number="228"></td>
        <td id="LC228" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">ensure</span></td>
      </tr>
      <tr>
        <td id="L229" class="blob-num js-line-number" data-line-number="229"></td>
        <td id="LC229" class="blob-code blob-code-inner js-file-line">    client_socket.close <span class="pl-k">rescue</span> <span class="pl-c1">nil</span></td>
      </tr>
      <tr>
        <td id="L230" class="blob-num js-line-number" data-line-number="230"></td>
        <td id="LC230" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def run</span></td>
      </tr>
      <tr>
        <td id="L231" class="blob-num js-line-number" data-line-number="231"></td>
        <td id="LC231" class="blob-code blob-code-inner js-file-line">
</td>
      </tr>
      <tr>
        <td id="L232" class="blob-num js-line-number" data-line-number="232"></td>
        <td id="LC232" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">public</span></td>
      </tr>
      <tr>
        <td id="L233" class="blob-num js-line-number" data-line-number="233"></td>
        <td id="LC233" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">def</span> <span class="pl-en">teardown</span></td>
      </tr>
      <tr>
        <td id="L234" class="blob-num js-line-number" data-line-number="234"></td>
        <td id="LC234" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">if</span> server?</td>
      </tr>
      <tr>
        <td id="L235" class="blob-num js-line-number" data-line-number="235"></td>
        <td id="LC235" class="blob-code blob-code-inner js-file-line">      <span class="pl-smi">@interrupted</span> <span class="pl-k">=</span> <span class="pl-c1">true</span></td>
      </tr>
      <tr>
        <td id="L236" class="blob-num js-line-number" data-line-number="236"></td>
        <td id="LC236" class="blob-code blob-code-inner js-file-line">    <span class="pl-k">end</span></td>
      </tr>
      <tr>
        <td id="L237" class="blob-num js-line-number" data-line-number="237"></td>
        <td id="LC237" class="blob-code blob-code-inner js-file-line">  <span class="pl-k">end</span> <span class="pl-c"># def teardown</span></td>
      </tr>
      <tr>
        <td id="L238" class="blob-num js-line-number" data-line-number="238"></td>
        <td id="LC238" class="blob-code blob-code-inner js-file-line"><span class="pl-k">end</span> <span class="pl-c"># class LogStash::Inputs::Tcp</span></td>
      </tr>
</table>

  </div>

</div>

<a href="#jump-to-line" rel="facebox[.linejump]" data-hotkey="l" style="display:none">Jump to Line</a>
<div id="jump-to-line" style="display:none">
  <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="" class="js-jump-to-line-form" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
    <input class="linejump-input js-jump-to-line-field" type="text" placeholder="Jump to line&hellip;" aria-label="Jump to line" autofocus>
    <button type="submit" class="btn">Go</button>
</form></div>

          </div>
        </div>
        <div class="modal-backdrop"></div>
      </div>
  </div>


    </div><!-- /.wrapper -->

      <div class="container">
  <div class="site-footer" role="contentinfo">
    <ul class="site-footer-links right">
        <li><a href="https://status.github.com/" data-ga-click="Footer, go to status, text:status">Status</a></li>
      <li><a href="https://developer.github.com" data-ga-click="Footer, go to api, text:api">API</a></li>
      <li><a href="https://training.github.com" data-ga-click="Footer, go to training, text:training">Training</a></li>
      <li><a href="https://shop.github.com" data-ga-click="Footer, go to shop, text:shop">Shop</a></li>
        <li><a href="https://github.com/blog" data-ga-click="Footer, go to blog, text:blog">Blog</a></li>
        <li><a href="https://github.com/about" data-ga-click="Footer, go to about, text:about">About</a></li>
        <li><a href="https://help.github.com" data-ga-click="Footer, go to help, text:help">Help</a></li>

    </ul>

    <a href="https://github.com" aria-label="Homepage">
      <span class="mega-octicon octicon-mark-github" title="GitHub"></span>
</a>
    <ul class="site-footer-links">
      <li>&copy; 2015 <span title="0.06665s from github-fe123-cp1-prd.iad.github.net">GitHub</span>, Inc.</li>
        <li><a href="https://github.com/site/terms" data-ga-click="Footer, go to terms, text:terms">Terms</a></li>
        <li><a href="https://github.com/site/privacy" data-ga-click="Footer, go to privacy, text:privacy">Privacy</a></li>
        <li><a href="https://github.com/security" data-ga-click="Footer, go to security, text:security">Security</a></li>
        <li><a href="https://github.com/contact" data-ga-click="Footer, go to contact, text:contact">Contact</a></li>
    </ul>
  </div>
</div>


    <div class="fullscreen-overlay js-fullscreen-overlay" id="fullscreen_overlay">
  <div class="fullscreen-container js-suggester-container">
    <div class="textarea-wrap">
      <textarea name="fullscreen-contents" id="fullscreen-contents" class="fullscreen-contents js-fullscreen-contents" placeholder="" aria-label=""></textarea>
      <div class="suggester-container">
        <div class="suggester fullscreen-suggester js-suggester js-navigation-container"></div>
      </div>
    </div>
  </div>
  <div class="fullscreen-sidebar">
    <a href="#" class="exit-fullscreen js-exit-fullscreen tooltipped tooltipped-w" aria-label="Exit Zen Mode">
      <span class="mega-octicon octicon-screen-normal"></span>
    </a>
    <a href="#" class="theme-switcher js-theme-switcher tooltipped tooltipped-w"
      aria-label="Switch themes">
      <span class="octicon octicon-color-mode"></span>
    </a>
  </div>
</div>



    
    

    <div id="ajax-error-message" class="flash flash-error">
      <span class="octicon octicon-alert"></span>
      <a href="#" class="octicon octicon-x flash-close js-ajax-error-dismiss" aria-label="Dismiss error"></a>
      Something went wrong with that request. Please try again.
    </div>


      <script crossorigin="anonymous" src="https://assets-cdn.github.com/assets/frameworks-eedcd4970c51d77d26b12825fc1fb1fbd554a880c0a8649a9cac6b63f1ee7cff.js"></script>
      <script async="async" crossorigin="anonymous" src="https://assets-cdn.github.com/assets/github/index-1af8eb3fd83c34afcee37eae4704e57d3bb35ccacee5574545665527ae02d731.js"></script>
      
      
  </body>
</html>

