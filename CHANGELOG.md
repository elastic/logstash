## 5.0.0-beta1 (Sep 21, 2016)
 - Migrated Logstash's internal logging framework to Log4j2. This enhancement provides the following features:
   - Support changing logging level dynamically at runtime through REST endpoints. New APIs have been exposed 
     under `_node/logging` to update log levels. Also a new endpoint `_node/logging` was added to return all 
     existing loggers.
   - Configurable file rotation policy for logs. Default is per-day.
   - Support component-level or plugin level log settings.
   - Unify logging across Logstash's Java and Ruby code.
   - Logs are now placed in `LS_HOME/logs` dir configurable via `path.logs` setting.
 - Breaking change: Set default log severity level to `INFO` instead of `WARN` to match Elasticsearch.
 - Show meaningful error message with an unknown CLI command ([#5748](https://github.com/elastic/logstash/issues/5748))
 - Monitoring API enhancements
   - Added `duration_in_millis` metric under `/_node/stats/pipeline/events`
   - Added JVM GC stats under `/_node/stats/jvm`
   - Removed the `/_node/mem` resource as it's been properly moved under `/_node/jvm/mem`
   - Added config reload stats under new resource type `_node/stats/pipeline/reloads`
   - Added config reload enabled/disabled info to `/_node/pipeline`
   - Added JVM GC strategy info under `/_node/jvm`
   - Ensure `?human` option works correctly for `hot_threads` API.
   - Make sure a non-existing API endpoint correctly returns 404 and a structured error message.
 - Plugin Developers: Improved nomenclature and methods for 'threadsafe' outputs. Removed `workers_not_supported` 
    method ([#5662](https://github.com/elastic/logstash/issues/5662))

### Output
  - Elasticsearch
    - Breaking Change: Index template for 5.0 has been changed to reflect Elasticsearch's mapping 
      changes. Most importantly, the subfield for string multi-fields has changed from `.raw` to `.keyword` 
      to match ES default behavior ([#386](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues/386))
    - Users installing ES 5.x and LS 5.x This change will not affect you and you will continue to use 
      the ES defaults. Users upgrading from LS 2.x to LS 5.x with ES 5.x LS will not force upgrade the template, 
      if logstash template already exists. This means you will still use .raw for sub-fields coming from 2.x. 
      If you choose to use the new template, you will have to reindex your data after the new template is 
      installed.
    - Added `check_connection_timeout` parameter which has a default of 10m

## 5.0.0-alpha5 (Aug 2, 2016)
 - Introduced a performance optimization called bi-values to store both JRuby and Java object types which will
   benefit plugins written in Ruby.
 - Added support for specifying a comma-separated list of resources to monitoring APIs. This can be used to 
   filter API response ([#5609](https://github.com/elastic/logstash/issues/5609))
 - `/_node/hot_threads?human=true` human option now returns a human readable format, not JSON.
 - Pipeline stats from `/_node/stats/pipeline` is also included in the parent `/_node/stats` 
   resource for completeness.
 
### Input
 - Beats
   - Reimplemented input in Java and to use asynchronous IO library Netty. These changes resulted in 
     up to 50% gains in throughput performance while preserving the original functionality ([#92](https://github.com/logstash-plugins/logstash-input-beats/issues/92)).
 - JDBC
   - Added support for providing encoding charset for strings not in UTF-8 format. `columns_charset` allows 
     you to override this encoding setting per-column ([#143](https://github.com/logstash-plugins/logstash-input-jdbc/issues/143))
 - HTTP Poller
   - Added meaningful error messages on missing trust/key-store password. Document the creation of a custom keystore.

### Filter
 - CSV
   - Added `autodetect_column_names` option to read column names from header.
 - Throttle
   - Reimplemented plugin to work with multiple threads, support asynchronous input and properly 
     tracks past events ([#4](https://github.com/logstash-plugins/logstash-filter-throttle/issues/4))

### Output
 - Elasticsearch
   - Added ability to choose different default template based on ES versions ([#401](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues/401))
 - Kafka
   - Input is a shareable instance across multiple pipeline workers. This ensures efficient use of resources like 
     broker TCP connections, internal producer buffers, etc ([#79](https://github.com/logstash-plugins/logstash-output-kafka/pull/79))
   - Added feature to allow regex patterns in topics so you can subscribe to multiple ones.

## 5.0.0-alpha4 (June 28, 2016)
 - Created a new `LS_HOME/data` directory to store plugin states, Logstash instance UUID and more. This directory 
   location is configurable via `path.data` ([#5404](https://github.com/elastic/logstash/issues/5404)).
 - Made `bin/logstash -V/--version` fast on Unix platforms.
 - Monitoring API: Added hostname, http_address, version as static fields for all APIs ([#5450](https://github.com/elastic/logstash/issues/5450)).
 - Added time tracking (wall-clock) to all individual filter and output instances. The goal is to help identify 
   what plugin configurations are consuming the most time. Exposed via `/_node/stats/pipeline`.
 - Added ` /_node` API which provides static information for OS, JVM and pipeline settings.  
 - Moved  `_plugins` api to `_node/plugins` endpoint.
 - Moved `hot_thread` API report to `_node/hot_thread` endpoint.
 - Add new `:list` property to configuration parameters. This will allow the user to specify one or more values.
 - Add new URI config validator/type. This allows plugin like the Elasticsearch output to safely URIs for 
   their configuration. Any password information in the URI will be masked when logged.
 
### Input
 - Kafka
   - Added support for Kafka broker 0.10.
 - HTTP
   - Fixed a bug where HTTP input plugin blocked stats API ([#51](https://github.com/logstash-plugins/logstash-input-http/issues/51)). 
 
### Output
 - Elasticsearch
   - ES output is now fully threadsafe. This means internal resources can be shared among multiple 
     `output { elasticsearch {} }` instances.
   - Sniffing improvements so any current connections don't have to be closed/reopened after a sniff round.
   - Introduced a connection pool to efficiently reuse connections to ES backends.
   - Added exponential backoff to connection retries with a ceiling of `retry_max_interval` which is the most time to 
     wait between retries, and `retry_initial_interval` which is the initial amount of time to wait. 
     `retry_initial_interval` will be increased exponentially between retries until a request succeeds.
     
 - Kafka
   - Added support for Kafka broker 0.10
   
### Filter
 - Grok
   - Added stats counter on grok matches and failures. This is exposed in `_node/stats/pipeline`
 - Date
   - Added stats counter on grok matches and failures. This is exposed in `_node/stats/pipeline`  

## 5.0.0-alpha3 (May 31, 2016)
 - Breaking Change: Introduced a new way to configure application settings for Logstash through a settings.yml file.
   This file is typically located in `LS_HOME/config`, or `/etc/logstash` when installed via packages. Logstash will not be 
   able to start without this file, so please make sure to pass in `path.settings` if you are starting Logstash manually after 
   installing it via a package (RPM, DEB) ([#4401](https://github.com/elastic/logstash/issues/4401)).
 - Breaking Change: Most of the long form options (https://www.elastic.co/guide/en/logstash/5.0/command-line-flags.html) 
   have been renamed to adhere to the yml dot notation to be used in the settings file. Short form options have not been
   changed ([#4401](https://github.com/elastic/logstash/issues/4401)).
 - Breaking Change: When Logstash is installed via DEB, RPM packages, it uses /usr/share and /var to install binaries and 
   config files respectively. Previously it used to install in /opt directory. This change was done to make the user experience 
   consistent with other Elastic products ([#5101](https://github.com/elastic/logstash/issues/5101)).
 - Breaking Change: For plugin developers, the Event class has a [new API](https://github.com/elastic/logstash/issues/5141) 
   to access its data. You will no longer be able to directly use the Event class through the ruby hash paradigm. All the 
   plugins packaged with Logstash has been updated to use the new API and their versions bumped to the next major.
 - Added support for systemd so you can now manage Logstash as a service on most Linux distributions ([#5012](https://github.com/elastic/logstash/issues/5012)).
 - Added new subcommand `generate` to `logstash-plugins` script that bootstraps a new plugin with the right directory structure
   and all the required files.
 - Logstash can now emit its log in structured, json format. Specify `--log.format=json` in the settings file or via 
   the command line ([#1569](https://github.com/elastic/logstash/issues/1569)).
 - Added more operational information to help run Logstash in production. `_node/stats` now shows file descriptors 
   and cpu information.
 - Fixed a bug where Logstash would not shutdown when CTRL-C was used, when using stdin input in configuration ([#1769](https://github.com/elastic/logstash/issues/1769)).
   
### Input
 - RabbitMQ: Removed `verify_ssl` option which was never used previously. To validate SSL certs use the 
   `ssl_certificate_path` and `ssl_certificate_password` config options ([#82](https://github.com/logstash-plugins/logstash-input-rabbitmq/issues/82)).
 - Stdin: This plugin is now non-blocking so you can use CTRL-C to stop Logstash.
 - JDBC: Added `jdbc_password_filepath` parameter for reading password from an external file ([#120](https://github.com/logstash-plugins/logstash-input-jdbc/issues/120)).
 
### Filter
 - XML:
   - Breaking: New configuration `suppress_empty` which defaults to `true`. Changed default behaviour of the plugin 
     in favor of avoiding mapping conflicts when reaching elasticsearch ([#24](https://github.com/logstash-plugins/logstash-filter-xml/issues/24)).
   - New configuration `force_content`. By default the filter expands attributes differently from content in xml 
     elements. This option allows you to force text content and attributes to always parse to a hash value ([#16](https://github.com/logstash-plugins/logstash-filter-xml/issues/16)).
   - Fixed a bug that ensure `target` is set when storing xml content in the event (`store_xml => true`).

## 5.0.0-alpha2 (May 3, 2016
### general
 - Added `--preserve` option to `bin/logstash-plugin` install command. This allows us to preserve gem options 
   which are already specified in `Gemfile`, which would have been previously overwritten.
 - When running any plugin related commands you can now use DEBUG=1, to give the user a bit more 
   information about what bundler is doing.
 - Added reload support to the init script so you can do `service logstash reload`
 - Fixed use of KILL_ON_STOP_TIMEOUT variable in init scripts which allows Logstash to force stop (#4991).
 - Upgrade to JRuby 1.7.25.
 - Filenames for Debian and RPM artifacts have been renamed to match Elasticsearch's naming scheme. The metadata 
   is still the same, so upgrades will not be affected. If you have automated downloads for Logstash, please make
   sure you have the updated URLs with the new names ([#5100](https://github.com/elastic/logstash/issues/5100)).  

### Input
 - Kafka: Fixed an issue where Snappy and LZ4 compression were not working.

### Filter
 - GeoIP: Added support for GeoIP2 city database and support for IPv6 lookups ([#23](https://github.com/logstash-plugins/logstash-filter-geoip/issues/23))

### Output
 - Elasticsearch: Added support for specifying ingest pipelines ([#410](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues/410))
 - Kafka: Fixed an issue where Snappy and LZ4 compression were not working ([#50](https://github.com/logstash-plugins/logstash-output-kafka/issues/50)).  


## 5.0.0-alpha1 (April 5, 2016)
### general
 - Added APIs to monitor the Logstash pipeline. You can now query information/stats about event 
   flow, JVM, and hot_threads.
 - Added dynamic config, a new feature to track config file for changes and restart the 
   pipeline (same process) with updated config changes. This feature can be enabled in two 
   ways: Passing a CLI long-form option `--auto-reload` or with short-form `-r`. Another 
   option, `--reload-interval <seconds>` controls how often LS should check the config files 
   for changes. Alternatively, if you don't start with the CLI option, you can send SIGHUP 
   or `kill -1` signal to LS to reload the config file, and restart the pipeline ([#4513](https://github.com/elastic/logstash/issues/4513)).
 - Added support to evaluate environment variables inside the Logstash config. You can also specify a 
   default if the variable is not defined. The syntax is `${myVar:default}` ([#3944](https://github.com/elastic/logstash/issues/3944)).
 - Improved throughput performance across the board (up by 2x in some configs) by implementing Event 
   representation in Java. Event is the main object that encapsulates data as it flows through 
   Logstash and provides APIs for the plugins to perform processing. This change also enables 
   faster serialization for future persistence work ([4191](https://github.com/elastic/logstash/issues/4191)).
 - Added ability to configure custom garbage collection log file using `$LS_LOG_DIR`.
 - `bin/plugin` in renamed to `bin/logstash-plugin`. This was renamed to prevent `PATH` being polluted 
   when other components of the Elastic stack are installed on the same instance ([#4891](https://github.com/elastic/logstash/pull/4891)).
 - Fixed a bug where new pipeline might break plugins by calling the `register` method twice causing 
   undesired behavior ([#4851](https://github.com/elastic/logstash/issues/4851)).
 - Made `JAVA_OPTS` and `LS_JAVA_OPTS` work consistently on Windows  ([#4758](https://github.com/elastic/logstash/pull/4758)).
 - Fixed bug where specifying JMX parameters in `LS_JAVA_OPTS` caused Logstash not to restart properly
   ([#4319](https://github.com/elastic/logstash/issues/4319)).
 - Fixed a bug where upgrading plugins with Manticore threw an error and sometimes corrupted installation ([#4818](https://github.com/elastic/logstash/issues/4818)).
 - Removed milestone warning that was displayed when the `--pluginpath` option was used to load plugins ([#4562](https://github.com/elastic/logstash/issues/4562)).
 - Upgraded to JRuby 1.7.24.
 - Reverted default output workers to 1. Perviously we had made output workers the same as number of pipeline
   workers ([#4877](https://github.com/elastic/logstash/issues/4877)).
   
### input
 - Beats
   - Enhanced to verify client certificates against CA ([#8](https://github.com/logstash-plugins/logstash-input-beats/issues/8)).
 - RabbitMQ
   - Breaking Change: Metadata is now disabled by default because it was regressing performance.
   - Improved performance by using an internal queue and bulk ACKs.
 - Redis
   - Increased the batch_size to 100 by default. This provides a big jump in throughput and 
     reduction in CPU utilization ([#25](https://github.com/logstash-plugins/logstash-input-redis/issues/25)).
 - JDBC
   - Added retry connection feature ([#91](https://github.com/logstash-plugins/logstash-input-jdbc/issues/91)).
 - Kafka
   - Breaking: Added support for 0.9 consumer API. This plugin now supports SSL based encryption. This release 
     changed a lot of configuration, so it is not backward compatible. Also, this version will not work with 
     Kafka 0.8 broker
   
### filter
  - DNS: 
    - Improved performance by adding caches to both successful and failed requests.
    - Added support for retrying with the `:max_retries` setting.
    - Lowered the default value of timeout from 2 to 0.5 seconds.

### output   
  - Elasticsearch
    - Bumped minimum manticore version to 0.5.4 which fixes a memory leak when sniffing 
      is used ([#392](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues/392)).
    - Fixed bug when updating documents with doc_as_upsert and scripting.
    - Made error messages more verbose and easier to parse by humans.
    - Retryable failures are now logged at the info level instead of warning.
  - Kafka
    - Breaking: Added support for 0.9 API. This plugin now supports SSL based encryption. This release 
      changed a lot of configuration, so it is not backward compatible. Also, this version will not work with 
      Kafka 0.8 broker      

## 1.5.5 (Oct 29, 2015)
### general
 - Update to JRuby 1.7.22
 - Improved default security configuration for SSL/TLS. Default is now TLS1.2 (#3955)
 - Fixed bug in JrJackson v0.3.5 when handing shared strings. This manifested into issues when 
   JrJackson was used in json codec and ES output. (#4048, #4055
 - Added beats input in the default plugins list

 ## output
 - HTTP: Fixed memory leak in http output with usage of manticore library (#24) 

## 2.0.0 (Oct 28, 2015)
No additional changes from RC1 release. Please see below for changes in individual
pre-releases.

## 2.0.0-rc1 (October 22, 2015)
### filter
 - Fixed metrics filter to work with ES 2.0 changes which does not allow dots in field names


## 2.0.0-beta3 (October 19, 2015)
### general
 - Fixed bug in JrJackson v0.3.5 when handing shared strings. This manifested into issues when 
   JrJackson was used in json codec and ES output. (#4048, #4055
 - Added beats input in the default plugins list
  
## output
 - Fixed memory leak in http output with usage of manticore library (#24)    

## 2.0.0-beta2 (October 14, 2015)
### general
 - Better shutdown handling in Logstash core and its plugins. Previously, the shutdown
   handling was through an injected exception which made it non-deterministic. The change
   introduces cleaner APIs in the core to signal a shutdown event which can be used by
   the plugins (#3210)
 - Upgrade to JrJackson version 0.3.5 which fixes numerous bugs and also provides performance
   boost for JSON handling (#3702)
 - Better defaults: Out of the box, the default value of the filter_workers (-w) setting will be set
   to half of the CPU cores of the machine. Increasing the workers provides parallelism in filter
   execution which is crucial when doing heavier processing like complex grok patterns or the useragent
   filter. You can still override the default by passing `-w` flag when starting Logstash (#3870)
 - Improved default security configuration for SSL/TLS. Default is now TLS1.2 (#3955)
 - Added obsolete setting which will cause a configuration error if a config marked obsolete
   is used. The purpose of :obsolete is to help inform users when a setting has been completely removed.
   The lifecycle of a plugin setting is now 4 phases: available, deprecated, obsolete, deleted. (#3977)

### input
 - Obsolete config settings (which were already deprecated): `debug`, `format`, `charset`, `message_format`.
   Logstash will not start if you use these settings.

### output
 - Obsolete config settings (which were already deprecated): `type`, `tags`, `exclude_tags`.
   Logstash will not start if you use these settings.

### filter
 - Obsolete config settings (which were already deprecated): `type`, `tags`, `exclude_tags`.
   Logstash will not start if you use these settings.

## 2.0.0-beta1 (September 15, 2015)
### output
  - Elasticsearch: 
    - Changed the default from node to http protocol.
    - Backward incompatible config options. Renamed host to hosts
    - Separate plugins for Java clients: transport and node options are not packaged by default but
      can be installed using the logstash-output-elasticsearch_java plugin.
    - Java client defaults to transport protocol  
  - Kafka: 
    - Update to new 0.8.2 Java producer API with new producer configuration
    - Backward incompatible config settings introduced to match Kafka options

## 1.5.4 (August 20, 2015)
### general
  - Reverted a change in our stronger ssl patch that prevented logstash-forwarder clients
    to connect to the lumberjack input, the server doesnt enforce `VERIFY_PEER` of clients. (#3657)
  - Fix incorrectly returned string encoding when using `Event#sprintf` ([#3723](https://github.com/elastic/logstash/pull/3723))

### input
  - Lumberjack: Fixed an incorrectly calculated window size of a payload that would make logstash loses events when dealing with congestion ([#3691](https://github.com/elastic/logstash/issues/3691))
  - Redis: Fixed typo in module name, causing the module to not be loaded ([#15](https://github.com/logstash-plugins/logstash-input-redis/issues/15))
  - Rabbitmq: Update redis `march hare` library to version 2.11.0 ([#33](https://github.com/logstash-plugins/logstash-input-rabbitmq/pull/33))
  - Http: Fix for missing `base64` require which was crashing Logstash ([#17](https://github.com/logstash-plugins/logstash-input-http/issues/17))
  - File: Fix double ingestion issue when using glob path ([3674](https://github.com/elastic/logstash/issues/3674)

### output
  - Lumberjack:
    - For SSL certificate verification, The client now enforces the `VERIFY_PEER` mode when 
       connecting to the server. ([#4](https://github.com/elastic/ruby-lumberjack/issues/4))
    - Added better handling of congestion scenario on the output by using a buffered send of events ([#7](https://github.com/logstash-plugins/logstash-output-lumberjack/pull/7))
  - Elasticsearch: Added the ability to update existing ES documents and support of upsert  -- if document doesn't exists, create it.([#116](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/116))

### Mixin
  - AWS: Correctly configure the proxy when using `V2` version of the mixin. ([#15](https://github.com/logstash-plugins/logstash-mixin-aws/issues/15))

## 1.5.3 (July 21, 2015)
### general
  - Added back `--pluginpath` command line option to `bin/logstash`. This loads plugin source code
    files from given file location (#3580).
  - Improved default security configuration for SSL (#3579).
  - For debian and rpm packages added ability to force stop Logstash. This can be enabled by setting
    the environment variable `KILL_ON_STOP_TIMEOUT=1` before stopping. If the Logstash process
    has not stopped within a reasonable time, this will force it to shutdown. 
    **Note**: Please be aware that you could lose inflight messages if you force stop
    Logstash (#3578).
  - Added a periodic report of inflight events during shutdown. This provides feedback to users
    about events being processed while shutdown is being handled (#3484).
  - Added ability to install and use pre-released plugins (beta and RC versions)
  - Fixed a permission issue in the init script for Debian and RPM packages. While running as 
    logstash user it was not possible to access files owned by supplemental groups (#1449).

### codec
  - Added support to handle JSON data with root arrays. Array entries will be split into
    individual events (#12).

### output
  - Elasticsearch: 
    - Added support for sending http indexing requests through a forwarding proxy (#199).
    - Added support for using PKI/client certificates for authenticating requests to a secure
      Elasticsearch cluster (#170).
  - RabbitMQ:
    - Fixed connection leakage issue (#10).
    - Properly reconnect on network disconnection (#9).

## 1.4.4 (July 21, 2015)
### general
  - Improved default security configuration for SSL
  - Update to Elasticsearch 1.7    

## 1.5.2 (July 1, 2015)
### general
  - Plugin manager: Added validation and warning when updating plugins between major versions (#3383).
  - Performance improvements: String interpolation is widely used in LS to create keys combining dynamic
    values from extracted fields. Added a caching mechanism where we compile this template on first use
    and reuse them subsequently, giving us a good performance gain in configs that do a lot of date 
    processing, sprintf, and use field reference syntax (#3425).
  - Added warning when LS is running on a JVM version which has known issues/bugs (#2547).  
  - Updated AWS based plugins to v2 of AWS ruby SDK. This involves an update to s3-input, s3-output,
    sqs-input, sns-output.

### input
  - Lumberjack: This input was not handling backpressure properly from downstream plugins and
    would continue to accept data, eventually running out of memory. We added a circuit breaker to stop
    accepting new connections when we detect this situation. Please note that `max_clients` setting 
    introduced in v0.1.9 has been deprecated. This setting temporarily solved the problem by configuring
    an upper limit to the number of LSF connections (#12).
  - Http: Added new input to receive data via http(s).
  - File: Fixed a critical bug where new files being added to a dir being watched would crash LS.
    This issue also happens when using a wildcard to watch files matching a pattern (#3473).

### output
  - SNS: Provided support to use codecs for formatting output (#3).
  - Elasticsearch: Added path setting for `http` protocol. When ES is running behind a proxy, you can use
    the path option to specify the exact location of the ES end point (#168).

## 1.5.1 (June 16, 2015)
### general
  - Fixed an issue which caused Logstash to hang when used with single worker (`-w 1`) configuration. 
    This issue was caused by a deadlock in the internal queue when the filter worker was trying to
    exclusively remove elements which conflicted with the periodic flushing in filters (#3361).
  - Fixed performance regression when using field reference syntax in config like `[tweet][username]`. 
    This fix increases throughput in certain configs by 30% (#3238)
  - Windows: Added support to launch Logstash from a path with spaces (#2904)
  - Update to jruby-1.7.20 which brings in numerous fixes. This will also make file input work
    properly on FreeBSD.
  - Fixed regression in 1.5.0 where conditionals spread over multiple lines in a config was not
    working properly (#2850)
  - Fixed a permission issue in rpm and debian repos. When Logstash was installed using these 
    repos, only the logstash user was able to run commands like `bin/logstash version` (#3249)

### filter
  - GeoIP: Logstash no longer crashes when IPv6 addresses are used in lookup (#8)

### output
  - Elasticsearch: 
    - Added an option to disable SSL certificate verification (#160)
    - Bulk requests were timing out because of aggressive timeout setting in the HTTP client.
      Restored this to 1.4.2 behavior where there are no timeouts by default. As a follow up
      to this, we will be exposing an option to control timeouts in the HTTP client (#103)
  - JIRA: 
    - Newly created issues now have description set (#3)
    - Summary field now expands variables in events
    - API authentication method changed from cookie to basic

## 1.4.3 (June 2, 2015)
### general
  - Updated to Elasticsearch 1.5.2, Kibana 3.1.2 and JRuby 1.7.17

### output
  - File: Sandbox output to protect against issues like creating new files
    outside defined paths

## 1.5.0 (May 14, 2015)
### general
  - Performance improvements: Logstash 1.5.0 is much faster -- we have improved the throughput 
    of grok filter in some cases by 100%. In our benchmark testing, using only grok filter and
    ingesting apache logs, throughput increased from 34K eps to 50K eps. 
    JSON serialization/deserialization are now implemented using JrJackson library which 
    improved performance significantly. Ingesting JSON events 1.3KB in size measured a throughput
    increase from 16Keps to 30K eps. With events 45KB in size, throughput increased from 
    850 eps to 3.5K eps
  - Fixed performance regressions from 1.4.2 especially for configurations which have 
    conditionals in filter and output. Throughput numbers are either inline with 1.4.2
    or improved for certain configurations (#2870)  
  - Add Plugin manager functionality to Logstash which allows to install, delete and 
    update Logstash plugins. Plugins are separated from core and published to RubyGems.org
  - Added the ability to install plugin gems built locally on top of Logstash. This will 
    help plugin developers iterate and test locally without having to publish plugins (#2779)  
  - With the release of Kibana 4, we have removed the `bin/logstash web` command and any reference 
    to Kibana from Logstash (#2661)
  - Windows: Significantly improved the initial user experience with Windows platform (#2504, #1426). 
    Fixed many issues related to File input. Added support for using the plugin 
    framework (installing, upgrading, removing)  
  - Deprecated elasticsearch_http output plugin: All functionality is ported to
    logstash-output-elasticsearch plugin using http protocol (#1757). If you try to use
    the elasticsearch_http plugin, it will log a deprecated notice now.   
  - Fixed issue in core which was causing Logstash to not shutdown properly (#2796)    
  - Added ability to add extra JVM options while running LS. You can use the LS_JAVA_OPTS 
    environment variable to add to the default JVM options set out of the box. You could also
    completely overwrite all the default options if you wish by setting JAVA_OPTS before
    starting Logstash (#2942)
  - Fixed a regression from 1.4.2 where removing a tag in filter fails if the input event is
    JSON formatted (#2261)
  - Fixed issue where setting workers > 1 would trigger messages like
    "You are using a deprecated config setting ..." (#2865) 
  - Remove ability to run multiple subcommands from bin/logstash like 
    bin/logstash agent -f something.conf -- web (#1747)  
  - Fixed Logstash crashing on converting from ASCII to UTF-8. This was caused by charset
    conversion issues in input codec (LOGSTASH-1789)
  - Allow storing 'metadata' to an event which is not sent/encoded on output. This eliminates
    the need for intermediate fields for example, while using date filter. (#1834)
  - Accept file and http uri in -f command line option for specifying config files (#1873)
  - Filters that generated events (multiline, clone, split, metrics) now propagate those events 
    correctly to future conditionals (#1431)
  - Fixed file descriptor leaks when using HTTP. The fix prevents Logstash from stalling, and
    in some cases crashing from out-of-memory errors (#1604, LOGSTASH-892)
  - You can now use LS_HOME/patterns directory to add generic patterns for those that may not be
    associated with a particular plugin. Patterns in this dir will be loaded by default (#2225)
  - We now check if the config file is correctly encoded. Otherwise we show a verbose error message
    to convert the failing config file(s) to UTF-8 (#LOGSTASH-1103)
  - Fixed bug in pipeline to gracefully teardown output workers when num workers > 1 (#2180)
  - Fixed nologin path in release debian packages (#2283)
  - Resolved issue where Logstash was crashing for users still using exclude_tags in their output
    configuration (#2323)
  - Allow spaces in field references like [hello world] (#1513)    

### input
  - Lumberjack: 
    - Fixed Logstash crashes with Java Out Of Memory because of TCP thread leaks (#LOGSTASH-2168)
    - Created a temporary fix to handle out of memory and eventual Logstash crash resulting from
      pipeline backpressure. With this fix, you can create an upper limit on the number of 
      Lumberjack connections after which no new connections will be accepted. This is defaulted
      to 1000 connections, but can be changed using the config (#3003)
    - Resolved issue where unrelated events were getting merged into a single event while using 
      this input with with the multiline codec (#2016)
    - Fixed Logstash crashing because it was using old jls-lumberjack version (#7)  
  - TCP: 
    - Fixed connection threads leak (#1509)
    - Fixed input host field also contains source port (LOGSTASH-1849)
  - Stdin: prevent overwrite of host field if already present in Event (#1668)
  - Kafka: 
    - Merged @joekiller's plugin to Logstash to get events from Kafka (#1472)
    - Added support for whitelisting and blacklisting topics in the input.
  - S3: 
    - Added IAM roles support so you can securely read and write events from S3 without providing your
      AWS credentials (#1575). 
    - Added support for using temporary credentials obtained from AWS STS (#1946)
    - AWS credentials can be specified through environment variables (#1619)  
  - RabbitMQ: 
    - Fixed march_hare client uses incorrect connection url (LOGSTASH-2276)
    - Use Bunny 1.5.0+ (#1894)
  - Twitter: added improvements, robustness, fixes. full_tweet option now works, we handle 
    Twitter rate limiting errors (#1471)
  - Syslog: if input does not match syslog format, add tag _grokparsefailure_sysloginputplugin
    which can be used to debug (#1593)
  - File: When shutting down Logstash with file input, it would log a "permissions denied"
    message. We fixed the underlying sinceDB issue while writing to a directory with no
    permissions (#2964, #2935, #2882, file-input#16)
  - File: Fixed a number of issues on Windows platform. These include:
    - Resolving file locking issues which was causing log files to not rotate (#1557, #1389)
    - Added support for using SinceDB to record multiple files' last read information (#1902)
    - Fixed encoding issues which applies to many inputs (#2507)
    - Resolved Logstash skipping lines when moving between files which are being followed (#1902)
  - CouchDB: Added new input plugin to fetch data from CouchDB. Using the _changes API, data can be kept
    in sync with any output like Elasticsearch by using this input  
  - EventLog: For Windows, this input gracefully shutsdown if there is a timeout while receiving events
    This also prevents Logstash from being stuck (#1672)
  - Heartbeat: We created a new input plugin for generating heartbeat messages at periodic intervals. 
    Use this to monitor Logstash -- you can measure the latency of the pipeline using these heartbeat 
    events, and also check for availability

### filter
  - Multiline: 
    - Fixed an issue where Logstash would crash while processing JSON formatted events on
      Java 8 (#10)
    - Handled cases where we unintentionally deduplicated lines, such as repeated lines in
      xml messages (#3) 
  - Grok: 
    - "break_on_match => false" option now works correctly (#1547)
    - allow user@hostname in commonapache log pattern (#1500 #1736)
    - use optimized ruby-grok library which improves throughput in some cases by 50% (#1657)
  - Date: 
    - Fixed match defaults to 1970-01-01 when none of the formats matches and UNIX format is present
      in the list (#1236, LOGSTASH-1597)
    - support parsing almost-ISO8601 patterns like 2001-11-06 20:45:45.123-0000 (without a T)
      which does not match %{TIMESTAMP_ISO8601}
  - KV: allows dynamic include/exclude keys. For example, if an event has a key field and the user 
    wants to parse out a value using the kv filter, the user should be able to 
    include_keys: [ "%{key}" ]
  - DNS: fixed add_tag adds tags even if filter was unsuccessful (#1785)
  - XML: fixed UndefinedConversionError with UTF-8 encoding (LOGSTASH-2246)
  - Mutate: 
    - Fixed nested field notation for convert option like 'convert => [ "[a][0]", "float" ]' (#1401)
    - Fixed issue where you can safely delete/rename fields which can have nil values (#2977)  
    - gsub evaluates variables like %{format} in the replacement text (#1529)
    - fixed confusing error message for invalid type conversion (#1656, LOGSTASH-2003)
    - Resolved issue where convert option was creating an extra field in the event (#2268)
    - Fixed issue where mutate with non-existent field was throwing an error (#2379)

### output
  - Elasticsearch:
    - We have improved the security of the Elasticsearch output, input, and filter by adding
      authentication and transport encryption support. In http protocol you can configure SSL/TLS to
      enable encryption and HTTP basic authentication to provide a username and password while making
      requests (#1453)
    - Added support to be more resilient to transient errors in Elasticsearch. Previously, partial
      failures from the bulk indexing functionality were not handled properly. With this fix, we added
      the ability to capture failed requests from Elasticsearch and retry them. Error codes like 
      429 (too many requests) will now be retried by default for 3 times. The number of retries and the
      interval between consecutive retries can be configured (#1631)
    - Logstash does not create a "message.raw" by default which is usually not_analyzed; this
      helps save disk space (#11)
    - Added sniffing config to be able to list machines in the cluster while using the transport client (#22) 
    - Deprecate the usage of index_type configuration. Added document_type to be consistent
      with document_id (#102)
    - Added warning when used with config embedded => true. Starting an embedded Elasticsearch
      node is only recommended while prototyping. This should never be used in 
      production setting (#99)
    - Added support for multiple hosts in configuration and enhanced stability
    - Logstash will not create a message.raw field by default now. Message field is not_analyzed
      by Elasticsearch and adding a multi-field was essentially doubling the disk space required,
      with no benefit

  - S3: 
    - Fixed a critical problem in the S3 Output plugin when using the size_file option. This could cause
      data loss and data corruption of old logs ()
    - Added IAM roles support so you can securely read and write events from S3 without providing your AWS
      credentials (#1575)
    - Added support for using temporary credentials obtained from AWS STS (#1946)
    - Fixed a bug when the tags were not set in the plain text format (#1626)

  - Kafka: merge @joekiller's plugin into Logstash to produce events to Kafka (#1472)
  - File: Added enhancements and validations for destination path. Absolute path cannot start with a
    dynamic string like /%{myfield}/, /test-%{myfield}/
  - RabbitMQ: fixed crash while running Logstash for longer periods, typically when there's no
    traffic on the logstash<->rabbitmq socket (LOGSTASH-1886)
  - Statsd: fixed issue of converting very small float numbers to scientific notation 
    like 9.3e-05 (#1670)
  - Fixed undefined method error when conditional on an output (#LOGSTASH-2288)
  
### codec
  - Netflow: Fixed a JSON serialization issue while using this codec (#2945)
  - Added new Elasticsearch bulk codec which can be used to read data formatted in the Elasticsearch 
    Bulk API (multiline json) format. For example, this codec can be used in combination with RabbitMQ 
    input to mirror the functionality of the RabbitMQ Elasticsearch river
  - Cloudfront: Added support for handling Amazon CloudFront events
  - Avro: We added a new codec for data serialization (#1566)

## 1.4.2 (June 24, 2014)
### general
  - fixed path issues when invoking bin/logstash outside its home directory

### input
  - bugfix: generator: fixed stdin option support
  - bugfix: file: fixed debian 7 path issue

### codecs
  - improvement: stdin/tcp: automatically select json_line and line codecs with the tcp and stdin streaming inputs
  - improvement: collectd: add support for NaN values

### outputs
  - improvement: nagios_nsca: fix external command invocation to avoid shell escaping

## 1.4.1 (May 6, 2014)
### General
  - bumped Elasticsearch to 1.1.1 and Kibana to 3.0.1
  - improved specs & testing (Colin Surprenant), packaging (Richard Pijnenburg) & doc (James Turnbull)
  - better $JAVA_HOME handling (Marc Chadwick)
  - fixed bin/plugin target dir for when installing out from form logstash home (lr1980)
  - fixed Accessors reset bug in Event#overwrite that was causing the infamous
    "undefined method `tv_sec'" bug with the multiline filter (Colin Surprenant)
  - fixed agent stalling when also using web option (Colin Surprenant)
  - fixed accessing array-indexed event fields (Jonathan Van Eenwyk)
  - new sysv init style scripts based on pleaserun (Richard Pijnenburg)
  - better handling of invalid command line parameters (LOGSTASH-2024, Colin Surprenant)
  - fixed running from a path containing spaces (LOGSTASH-1983, Colin Surprenant)

### inputs
  - improvement: rabbitmq: upgraded Bunny gem to 1.1.8, fixes a threading leak and improves
    latency (Michael Klishin)
  - improvement: twitter: added "full_tweet" option (Jordan Sissel)
  - improvement: generator: fixed the example doc (LOGSTASH-2093, Jason Kendall)
  - improvement: imap: option to disable certificate validation (Sverre Bakke)

### codecs
  - new: collectd: better performance & error handling than collectd input (Aaron Mildenstein)
  - improvement: graphite: removed unused charset option (Colin Surprenant)
  - improvement: json_spooler: is now deprecated (Colin Surprenant)
  - improvement: proper charset support in all codecs (Colin Surprenant)

### filters
  - bugfix: date: on_success actions only when date parsing actually succeed (Philippe Weber)
  - bugfix: multiline: "undefined method `tv_sec'" fix (Colin Surprenant)
  - bugfix: multiline: fix for "undefined method `[]' for nil:NilClass" (#1258, Colin Surprenant)
  - improvement: date: fix specs for non "en" locale (Olivier Le Moal)
  - improvement: grok: better pattern for RFC-5424 syslog format (Guillaume Espanel)
  - improvement: grok: refactored the LOGLEVEL pattern (Lorenzo González)
  - improvement: grok: fix example doc (LOGSTASH-2093, Jason Kendall)
  - improvement: metrics: document .pXX metric (Juarez Bochi)

### outputs
  - improvement: rabbitmq: upgraded Bunny gem to 1.1.8, fixes a threading leak and improves
    latency (Michael Klishin)
  - improvement: elasticsearch: start embedded server before creating a client to fix discovery
    problems "waited for 30s ..." (Jordan Sissel)
  - improvement: elasticsearch: have embedded ES use "bind_host" option for "network.host"
    ES config (Jordan Sissel)

## 1.4.0 (March 20, 2014)
### General
  - We've included some upgrade-specific release notes with more details about
    the tarball changes and contrib packaging here:
    http://logstash.net/docs/1.4.0/release-notes
  - Ships with Kibana 3.0.0
  - Much faster field reference implementation (Colin Surprenant)
  - Fix a bug in character encoding which would cause inputs using non-UTF-8
    codecs to accidentally skip re-encoding the text to UTF-8. This should
    solve a great number of UTF-8-related bugs. (Colin Surprenant)
  - Fixes missing gem  for logstash web which was broken in 1.4.0 beta1
    (LOGSTASH-1918, Jordan Sissel)
  - Fix 'help' output being emitted twice when --help is invoked.
    (LOGSTASH-1952, #1168)
  - Logstash now supports deletes! See outputs section below.
  - Update template to fit ES 1.0 API changes (untergeek)
  - Lots of Makefile, gem and build improvements courtesy of untergeek, Faye
    Salwin, mrsolo, ronnocol, electrical, et al
  - Add `env` command so you can run arbitrary commands with the logstash
    environment setup (jordansissel)
  - Bug fixes (lots).  Did I mention bug fixes? (Thanks, community!)
  - Elasticsearch 1.0 libraries are now included. See the Elasticsearch
    release notes for details: http://www.elasticsearch.org/downloads/1-0-0/
  - Kibana 3 milestone 5 is included as the 'web' process.
  - An empty --pluginpath directory is now accepted (#917, Richard Pijnenburg)
  - Piles of documentation improvements! A brand new introductory tutorial is
    included, and many of the popular plugins have had their docs greatly
    improved. This effort was lead by Kurt Hurtado with assists by James
    Turnbull, Aaron Mildenstein, Brad Fritz, and others.
  - Testing was another focus of this release. We added many more tests
    to help us prevent regressions and verify expected behavior. Helping with
    this effort was Richard Pijnenburg, Jordan Sissel, and others.
  - The 'debug' setting was removed from most plugins. Prior to this,
    most plugins advertised the availability of this setting but actually
    did not use it (#996, Jordan Sissel).
  - bugfix: --pluginpath now lets you load codecs. (#1077, Sergey Zhemzhitsky)

### inputs
  - bugfix: collectd: Improve handling of 'NaN' values (#1015, Pieter Lexis)
  - bugfix: snmptrap: Fixes exception when not specifying yamlmibdir (#950, Andres Koetsier)
  - improvement: Add Multi-threaded workers and queues to UDP input (johnarnold + untergeek)
  - improvement: log4j: port now defaults to 4560, the default log4j
    SocketAppender port. (#757, davux)
  - bugfix: rabbitmq: auto_delete and exclusive now default to 'false'.
    The previous version's defaults caused data loss on logstash restarts.
    Further, these settings are recommended by the RabbitMQ folks. (#864,
    Michael Klishin)
    This change breaks past default behavior, so just be aware. (Michael
    Klishin)
  - bugfix: collectd: fix some type calculation bugs (#905, Pieter Lexis)
  - improvement: collectd: Now supports decryption and signature verification
    (#905, Pieter Lexis)
  - improvement: wmi: now supports remote hosts (#918, Richard Pijnenburg)
  - bugfix: elasticsearch: Long scrollids now work correctly (#935, Jonathan
    Van Eenwyk)
  - bugfix: tcp: the 'host' field is correctly set now if you are using the
    json codec and include a 'host' field in your events (#937, Jordan Sissel)
  - bugfix: file: the 'host' field is correctly set now if you are using the
    json codec and include a 'host' field in your events (#949, Piotr
    Popieluch)
  - bugfix: udp: the 'host' field is correctly set now if you are using the
    json codec and include a 'host' field in your events (#965, Devin
    Christensen)
  - bugfix: syslog: fix regression (#986, Joshua Bussdieker)

### codecs
  - improvement: netflow: You can now specify your own netflow field
    definitions using the 'definitions' setting. See the netflow codec
    docs for examples on how to do this. (#808, Matt Dainty)

### filters
  - bugfix: clone: Correctly clone events with numeric field values.
    (LOGSTASH-1225, #1158, Darren Holloway)
  - bugfix: zeromq: Add `timeout` and `retries` settings for retrying on
    request failures. Also adds `add_tag_on_timeout` so you can act on retry
    failures. (logstash-contrib#23, Michael Hart)
  - new: fingerprint: Checksum, anonymize, generate UUIDs, etc! A generalized
    solution to replace the following filters: uuid, checksum, and anonymize.
    (#907, Richard Pijnenburg)
  - new: throttle: Allows you to tag or add fields to events that occur with a
    given frequency. One use case is to have logstash email you only once if an
    event occurs at least 3 times in 60 seconds. (#940, Mike Pilone) -
  - improvement: translate: A new 'refresh_interval' setting lets you tell
    logstash to periodically try reloading the 'dictionary_path' file
    without requiring a restart. (#975, Kurt Hurtado)
  - improvement: geoip: Now safe to use with multiple filter workers and
    (#990, #997, LOGSTASH-1842; Avleen Vig, Jordan Sissel)
  - improvement: metrics: Now safe to use with multiple filter workers (#993,
    Bernd Ahlers)
  - bugfix: date: Fix regression that caused times to be local time instead of
    the intended timezone of UTC. (#1010, Jordan Sissel)
  - bugfix: geoip: Fix encoding of fields created by geoip lookups
    (LOGSTASH-1354, LOGSTASH-1372, LOGSTASH-1853, #1054, #1058; Jordan Sissel,
    Nick Ethier)

### outputs
  - bugfix: elasticsearch: flush any buffered events on logstash shutdown
    (#1175)
  - feature: riemann: Automatically map event fields to riemann event fields
    (logstash-contrib#15, Byron Pezan)
  - bugfix: lumberjack: fix off-by-one errors causing writes to another
    logstash agent to block indefinitely
  - bugfix: elasticsearch: Fix NameError Socket crash on startup
    (LOGSTASH-1974, #1167)
  - improvement: Added `action` awesomeness to elasticsearch output (#1105, jordansissel)
  - improvement: Implement `protocol => http` in elasticsearch output (#1105, jordansissel)
  - bugfix: fix broken pipe output to allow EBADF instead of EPIPE,
    allowing pipe command to be restarted (#974, Paweł Puterla)
  - improvement: Adding dns resolution to lumberjack output (#1048, Nathan Burns )
  - improvement: added pre- and post-messages to the IRC output (#1111, Lance O'Connor)
  - bugfix: pipe: fix handling of command failures (#1023, #1034, LOGSTASH-1860; ronnocol, Jordan Sissel)
  - improvement: lumberjack: now supports codecs (#1048, LOGSTASH-1680; Nathan Burns)

## 1.3.3 (January 17, 2014)
### general
  - bugfix: Fix SSL cert load problem on plugins using aws-sdk: S3, SNS, etc.
    (LOGSTASH-1778, LOGSTASH-1787, LOGSTASH-1784, #924; Adam Peck)
  - bugfix: Fix library load problems for aws-sdk (LOGSTASH-1718, #923; Jordan
    Sissel)
  - bugfix: Fix regression introduced in 1.3.2 while trying to improve time
    parsing performance. (LOGSTASH-1732, LOGSTASH-1738, #913; Jordan Sissel)
  - bugfix: rabbitmq: honour the passive option when creating queues.
    (LOGSTASH-1461, Tim Potter)

### codecs
  - bugfix: json_lines, json: Fix bug causing invalid json to be incorrectly
    handled with respect to encoding (#920, LOGSTASH-1595; Jordan Sissel)

## 1.3.2 (December 23, 2013)
### upgrade notes
  - Users of logstash 1.3.0 or 1.3.1 should set 'template_overwrite => true' in
    your elasticsearch (or elasticsearch_http) outputs before upgrading to this
    version to ensure you receive the fixed index template.

### general
  - web: don't crash if an invalid http request was sent
    (#878, LOGSTASH-704; Jordan Sissel)
  - Ships with Elasticsearch 0.90.9
  - logstash will now try to make sure the @timestamp field is of the
    correct format.
  - Fix a bug in 1.3.1/1.3.0's elasticsearch index template causing phrase
    searching to not work. Added tests to ensure search behavior works as
    expected with this template. (Aaron Mildenstein, Jordan Sissel)
  - Update README.md to be consistent with Makefile use of JRuby 1.7.8
  - Time parsing in things like the json codec (and other similar parts of
    logstash) are *much* faster now. This fixes a speed regression that was
    introduced in logstash 1.2.0.

### filters
  - improvement: date: roughly 20% faster (Jordan Sissel)

### outputs
  - new: csv: write csv format to files output. (Matt Gray)
    (This output will become a codec usable with file output in the next
     major version!)

## 1.3.1 (December 11, 2013)
### general
  - Fix path to the built-in elasticsearch index template

## 1.3.0 (December 11, 2013)
### general
  - oops: The --help flag now reports help again, instead of barfing an "I need
    help" exception (LOGSTASH-1436, LOGSTASH-1392; Jordan Sissel)
  - Resolved encoding errors caused by environmental configurations, such as
    'InvalidByteSequenceError ... on US-ASCII' (LOGSTASH-1595, #842;
    Jordan Sissel)
  - Fix bug causing "no such file to load -- base64" (LOGSTASH-1310,
    LOGSTASH-1519, LOGSTASH-1325, LOGSTASH-1522, #834; Jordan Sissel)
  - Elasticsearch version 0.90.7
  - Bug fixes galore!

### inputs
  - new: collectd: receive metrics from collectd's network protocol
    (#785, Aaron Mildenstein)
  - bugfix: gelf: handle chunked gelf message properly (#718, Thomas De Smedt)
  - bugfix: s3: fix bug in region endpoint setting (#740, Andrea Ascari)
  - bugfix: pipe: restart the command when it finishes (#754, Jonathan Van
    Eenwyk)
  - bugfix: redis: if redis fails, reconnect. (#767, LOGSTASH-1475; Jordan Sissel)
  - feature: imap: add 'content_type' setting for multipart messages and
    choosing the part that becomes the event message. (#784, Brad Fritz)
  - bugfix: zeromq: don't override the 'host' field if the event already
    has one. (Jordan Sissel)
  - bugfix: ganglia: fix regressions; plugin should work again (LOGSTASH-1655,
    #818; Jordan Sissel)
  - bugfix: Fix missing library in sqs input (#775, LOGSTASH-1294; Toby
    Collier)

### filters
  - new: unique: removes duplicate values from a given field in an event.
    (#676, Adam Tucker)
  - new: elapsed: time duration between two tagged events. (#713, Andrea Forni)
  - new: i18n: currently supports 'transliterate' which does best-effort
    conversion of text to "plain" letters. Like 'ó' to 'o'.  (#671,
    Juarez Bochi)
  - bugfix: restore filter flushing thread (LOGSTASH-1284, #689; Bernd Ahlers)
  - new: elasticsearch: query elasticsearch and update your event based on the
    results. (#707, Jonathan Van Eenwyk)
  - new: sumnumbers: finds all numbers in a message and sums them (#752, Avleen
    Vig)
  - feature: geoip: new field 'location' is GeoJSON derived from the lon/lat
    coordinates for use with elasticsearch, kibana, and anything else that
    understands GeoJSON (#763, Aaron Mildenstein)
  - new: punct: Removes all text except punctuation and stores it in another
    field. Useful for as a means for fingerprinting events. (#813, Guixing Bai)
  - feature: metrics: Make percentiles configurable. Also make rates (1, 5,
    15-minute) optional. (#817, Juarez Bochi)

### codecs
  - new: compressed_spooler: batches events and sends/receives them in
    compressed form. Useful over high latency links or with transports
    with higher-than-desired transmission costs. (Avleen Vig)
  - new: fluent: receive data serialized using the Fluent::Logger for easier
    migration away from fluentd or for folks who simply like the logger
    library (#759, Jordan Sissel)
  - new: edn: encode and decode the EDN serialization format. Commonly used
    in Clojure. For more details, see: https://github.com/edn-format/edn
    (#778, Lee Hinman)
  - bugfix: oldlogstashjson: Fix encoding to work correctly. (#788, #795;
    Brad Fritz)
  - bugfix: oldlogstashjson: Fallback to plain text on invalid JSON
    (LOGSTASH-1534, #850; Jordan Sissel)

### outputs
  - feature: elasticsearch and elasticsearch_http now will apply a default
    index mapping template (included) which has the settings recommended by
    Elasticsearch for Logstash specifically.
    Configuration options allow disabling this feature and providing a path
    to your own template. (#826, #839; Aaron Mildenstein)
  - feature: elasticsearch_http: optional 'user' and 'password' settings to
    make use of http authentication (LOGSTASH-902, #684; Ian Neubert)
  - new: google_bigquery: upload logs to bigquery for analysis later (Rodrigo
    De Castro)
  - bugfix: datadog_metrics: fix validation bug (#789, Ian Paredes)
  - feature: elasticsearch: new 'transport' setting letting you tell logstash
    to act as a cluster node (default, prior behavior) or as a 'transport
    client'. With the new 'transport' mode, your firewall rules may be simpler
    (unicast, one direction) and transport clients do not show up in your
    cluster node list. (LOGSTASH-102, #841; Jordan Sissel)
  - feature: elasticsearch: new 'bind_port setting for 'node' protocol which
    lets you chose the local port to bind on (#841, Jordan Sissel)
  - bugfix: Fix missing library in sqs input (#775, LOGSTASH-1294; Toby
    Collier)

## 1.2.2 (October 22, 2013)
### general
  - new 'worker' setting for outputs. This helps improve throughput on
    request-oriented outputs such as redis, rabbitmq, elasticsearch,
    elasticsearch_http, etc. Workers run in separate threads each handling
    events as they come in. This allows you to linearly scale up outputs across
    cores or as blocking-io permits.
  - grok performance is up 600%
  - lots of bug fixes
  - bugfixes to conditionals (#682, Matt Dainty)
  - rabbitmq now replaces the old deprecated amqp plugins. amqp plugins are
    removed.
  - inputs will now do their best to handle text which is encoded differently
    than the charset you have specified (LOGSTASH-1443, Jordan Sissel)

### inputs
  - bugfix: udp: respects teardown requests via SIGINT, etc (LOGSTASH-1290,
    Jordan Sissel)
  - bugfix: rabbitmq: disable automatic connection recovery (LOGSTASH-1350,
    #641, #642; Michael Klishin)
  - bugfix: twitter: works again (#640, Bernd Ahlers)
  - compatibility: Restored the old 'format' setting behavior. It is still
    deprecated, but was accidentally removed in 1.2.0. It will be removed
    later, but is restored as part of our backwards-compat promise (Jordan
    Sissel)
  - bugfix: s3: fix LOGSTASH-1321 and LOGSTASH-1319 (Richard Pijnenburg)
  - bugfix: log4j: fix typo (Jordan Sissel)
  - bugfix: rabbitmq: disable automatic connection recover because logstash
    will handle it (LOGSTASH-1350, Michael Klishin)
  - bugfix: heroku: works again (LOGSTASH-1347, #643; Bernd Ahlers)
  - bugfix: tcp: improve detection of closed connections to reduce lost events
    (Jordan Sissel)
  - bugfix: elasticsearch: now works correctly (#670, Richard Pijnenburg)
  - improvement: elasticsearch: make size and scroll time configurable (#670,
    Richard Pijnenburg)
  - improvement: elasticsearch: tunable search type (#670, Richard Pijnenburg)
  - compatibility: restore 'format' setting which was accidentally removed in
    1.2.0. This feature is still deprecated, but it has been restored
    temporarily as part of our backwards compatibility promise. (#706, Jordan
    Sissel)
  - bugfix: syslog: fix socket leakage (#704, Bernd Ahlers)
  - improvement: all aws-related plugins: Add proxy_uri setting (#714, Malthe
    Borch)
  - bugfix: unix: fix variable name crash (#720, Nikolay Bryskin)

### codecs
  - new: graphite: parse graphite formated events (Nick Ethier)
  - new: json_lines: parse streams that are lines of json objects (#731, Nick
    Ethier)
  - bugfix: multiline: time is now correctly in UTC. (Jordan Sissel)
  - bugfix: oldlogstashjson: improved conversion of old logstash json to the
    new schema (#654, Jordan Sissel)
  - bugfix: oldlogstashjson: fix typo breaking encoding (#665, Tom Howe)
  - bugfix: json: now assumes json delimited by newline character
    (LOGSTASH-1332, #710; Nick Ethier)
  - improvements: netflow: new target and versions settings (#686, Matt Dainty)

### filters
  - performance: grok: 6.3x performance improvement (#681, Jordan Sissel)
  - bugfix: geoip: empty values (nil, empty string) are not put into the event
    anymore. (Jordan Sissel)
  - bugfix: geoip: allow using Maxmind's ASN database (LOGSTASH-1394, #694;
    Bernd Ahlers)
  - improvement: kv: target will now overwrite any existing fields, including
    the source (Jordan Sissel).
  - improvement: Kv: 'prefix' setting now respects sprintf (LOGSTASH-913,
    #647; Richard Pijnenburg)
  - checksum: sha128 was not a valid digest, removed from list
  - feature: metrics: added clear_interval and flush_interval parameters for
    setting flush rates and when to clear metrics (#545)
  - new: collate: group events by time and/or count into a single event. (#609,
    Neway Liu)
  - feature: date: now supports a 'target' field for writing the timestamp into
    a field other than @timestamp. (#625, Jonathan Van Eenwyk)
  - bugfix: riemann: event tagging works again (#631, Marc Fournier)
  - improvement: grok: IPV6 pattern (#623, Matt Dainty)
  - improvement: metrics: add clear_interval and flush_interval settings (#545,
    Juarez Bochi)
  - improvement: useragent: include operating system details (#656, Philip
    Kubat)
  - improvement: csv: new quote_char setting (#725, Alex Markham)

### outputs
  - feature: all outputs have a 'worker' setting  now that allows you to
    perform more work at the same time. This is useful for plugins like
    elasticsearch_http, redis, etc, which can bottleneck on waiting for
    requests to complete but would otherwise be happy processing more
    simultaneous requests. (#708, Jordan Sissel)
  - bugfix: elasticsearch: requests are now synchronous. This avoid overloading
    the client and server with unlimited in-flight requests. (#688, Jordan
    Sissel)
  - bugfix: elasticsearch_http: fix bug when sending multibyte utf-8 events
    (LOGSTASH-1328, #678, #679, #695; Steve Merrill, Christian Winther,
    NickEthier, Jordan Sissel)
  - performance: elasticsearch_http: http client library uses TCP_NODELAY now
    which dramatically improves performance. (#696, Jordan Sissel)
  - feature: elasticsearch_http now supports a 'replication' setting to
    allow you to choose how you wait for the response. THe default is 'sync'
    which waits for all replica shards to be written. If you set it to 'async'
    then all index requests will respond once only the primary shards have been
    written and the replica shards will be written later. This can improve
    throughput. (#700, Nick Ethier, Jordan Sissel)
  - bugfix: elasticsearch: the default port range is now 9300-9305; the older
    range up to 9400 was unnecessary and could cause problems for the
    elasticsearch cluster in some cases.
  - improvement: aws-based outputs (e.g. cloudwatch) now support proxy uri.
  - bugfix: rabbitmq: disable automatic connection recovery (LOGSTASH-1350)
    (#642)
  - bugfix: riemann: fixed tagging of riemann events (#631)
  - bugfix: s3: fix LOGSTASH-1321 and LOGSTASH-1319 (#636, #645; Richard
    Pijnenburg)
  - bugfix: mongodb: Fix mongodb auth (LOGSTASH-1371, #659; bitsofinfo)
  - bugfix: datadog: Fix time conversion (LOGSTASH-1427, #690; Bernd Ahlers)
  - bugfix: statsd: Permit plain floating point values correctly in the
    config. Example: sample_rate => 0.5 (LOGSTASH-1441, #705; Jordan Sissel)
  - bugfix: syslog: Fix timestamp date formation. 'timestamp' setting is now
    deprecated and the format of the time depends on your rfc selection.
    (LOGSTASH-1423, #692, #739; Jordan Sissel, Bernd Ahlers)

### patterns
  - improvement: added IPV6 support to IP pattern (#623)

## 1.2.1 (September 7, 2013)
### general
  - This is primarily a bugfix/stability release based on feedback from 1.2.0
  - web: kibana's default dashboard now works with the new logstash 1.2 schema.
  - docs: updated the tutorials to work in logstash 1.2.x
  - agent: Restored the --configtest flag (unintentionally removed from 1.2.0)
  - deprecation: Using deprecated plugin settings can now advise you on a
    corrective path to take. One example is the 'type' setting on filters and
    outputs will now advise you to use conditionals and give an example.
  - conditionals: The "not in" operator is now supported.

### inputs
  - bugfix: pipe: reopen the pipe and retry on any error. (#619, Jonathan Van
    Eenwyk)
  - bugfix: syslog: 'message' field no longer appears as an array.
  - bugfix: rabbitmq: can now bind the queue to the exchange (#624, #628,
    LOGSTASH-1300, patches by Jonathan Tron and Jonathan Van Eenwyk)

### codecs
  - compatibility: json: if data given is not valid as json will now be used as
    the "message" of an event . This restores the older behavior when using
    1.1.13's "format => json" feature on inputs. (LOGSTASH-1299)
  - new: netflow: process netflow data (#580, patches by Nikolay Bryskin and
    Matt Dainty)

### filters
  - bugfix: multiline: the multiline filter returns! It was unintentionally
    removed from the previous (1.2.0) release.
  - bugfix: json_encode: fix a syntax error in the code. (LOGSTASH-1296)
  - feature: kv: now captures duplicate field names as a list, so 'foo=bar
    foo=baz' becomes the field 'foo' with value ['bar', 'baz'] (an array).
    (#622, patch by Matt Dainty)

### outputs
  - new: google_cloud_storage: archive logs to Google Cloud Storage (#572,
    Rodrigo De Castro)
  - bugfix: fixed bug with 'tags' and 'exclude_tags' on outputs that would
    crash if the event had no tags. (LOGSTASH-1286)

## 1.2.0 (September 3, 2013)
### general
  - The logstash json schema has changed. (LOGSTASH-675)
    For prior logstash users, you will be impacted one of several ways:
    * You should check your elasticsearch templates and update them accordingly.
    * If you want to reindex old data from elasticsearch with the new schema,
      you should be able to do this with the elasticsearch input. Just make
      sure you set 'codec => oldlogstashjson' in your elasticsearch input.
  - The old logstash web ui has been replaced by Kibana 3. Kibana is a far
    superior search and analytics interface.
  - New feature: conditionals! You can now make "if this, then ..." decisions
    in your filters or outputs. See the docs here:
    http://logstash.net/docs/latest/configuration#conditionals
  - A new syntax exists for referencing fields (LOGSTASH-1153). This replaces
    the prior and undocumented syntax for field access (was 'foo.bar' and is
    now '[foo][bar]'). Learn more about this here:
    http://logstash.net/docs/latest/configuration#fieldreferences
  - A saner hash syntax in the logstash config is now supported. It uses the
    perl/ruby hash-rocket syntax: { "key" => "value", ... } (LOGSTASH-728)
  - ElasticSearch version 0.90.3 is included. (#486, Gang Chen)
  - The elasticsearch plugin now uses the bulk index api which should result
    in lower cpu usage as well as higher performance than the previous
    logstash version.
  - Many deprecated features have been removed. If your config caused
    deprecation warnings on startup in logstash v1.1.13, there is a good
    chance that these deprecated settings are now absent.
  - 'type' is no longer a required setting on inputs.
  - New plugin type: codec. Used to implement decoding of events for inputs and
    encoding of events for outputs. Codecs allow us to separate transport (like
    tcp, redis, rabbitmq) from serialization (gzip text, json, msgpack, etc).
  - Improved error messages that try to be helpful. If you see bad or confusing
    error messages, it is a bug, so let us know! (Patch by Nick Ethier)
  - The old 'plugin status' concept has been replaced by 'milestones'
    (LOGSTASH-1137)
  - SIGHUP should cause logstash to reopen it's logfile if you are using the
    --log flag

### inputs
  - new: s3: reads files from s3 (#537, patch by Mathieu Guillaume)
  - feature: imap: now marks emails as read (#542, Raffael Schmid)
  - feature: imap: lets you delete read email (#591, Jonathan Van Eenwyk)
  - feature: rabbitmq: now well-supported again (patches by Michael Klishin)
  - bugfix: gelf: work around gelf parser errors (#476, patch by Chris McCoy)
  - broken: the twitter input is disabled because the twitter stream v1 api is
    no longer supported and I couldn't find a replacement library that works
    under JRuby.
  - new: sqlite input (#484, patch by Evan Livingston)
  - improvement: snmptrap: new 'yamlmibdir' setting for specifying an external
    source for MIB definitions. (#477, patch by Dick Davies)
  - improvement: stomp: vhost support (#490, patch by Matt Dainty)
  - new: unix: unix socket input (#496, patch by Nikolay Bryskin)
  - new: wmi: for querying wmi (windows). (#497, patch by Philip Seidel)
  - improvement: sqs: new id_field and md5_field settings (LOGSTASH-1118, Louis
    Zuckerman)

### filters
  - feature: grok: 'singles' now defaults to true.
  - bugfix: grep: allow repeating a field in the hash config (LOGSTASH-919)
  - feature: specify timezone in date filter (#470, patch by Philippe Weber)
  - feature: grok setting 'overwrite' now lets you overwrite fields instead
    of appending to them.
  - feature: the useragent filter now defaults to writing results to the top
    level of the event instead of "ua"
  - feature: grok now defaults 'singles' to true, meaning captured fields are
    stored as single values in most cases instead of the old behavior of being
    captured as an array of values.
  - new: json_encoder filter (#554, patch by Ralph Meijer)
  - new: cipher: gives you many options for encrypting fields (#493, patch by
    saez0pub)
  - feature: kv: new settings include_fields and exclude_fields. (patch by
    Piavlo)
  - feature: geoip: new 'target' setting for where to write geoip results.
    (#491, patch by Richard Pijnenburg)
  - feature: dns: now accepts custom nameservers to query (#495, patch by
    Nikolay Bryskin)
  - feature: dns: now accepts a timeout setting (#507, patch by Jay Luker)
  - bugfix: ruby: multiple ruby filter instances now work (#501, patch by
    Nikolay Bryskin)
  - feature: uuid: new filter to add a uuid to each event (#531, Tomas Doran)
  - feature: useragent: added 'prefix' setting to prefix field names created
    by this filter. (#524, patch by Jay Luker)
  - bugfix: mutate: strip works now (#590, Jonathan Van Eenwyk)
  - new: extractnumbers: extract all numbers from a message (#579, patch by
    Pablo Barrera)

### outputs
  - new: jira: create jira tickets from an event (#536, patch by Martin Cleaver)
  - feature: rabbitmq: now well-supported again (patches by Michael Klishin)
  - improvement: stomp: vhost support (Patch by Matt Dainty)
  - feature: elasticsearch: now uses the bulk index api and supports
    a tunable bulk flushing size.
  - feature: elasticsearch_http: will now flush when idle instead of always
    waiting for a full buffer. This helps in slow-sender situations such
    as testing by hand.
  - feature: irc: add messages_per_second tunable (LOGSTASH-962)
  - bugfix: email: restored initial really useful documentation
  - improvement: emails: allow @message, @source, @... in match (LOGSTASH-826,
    LOGSTASH-823)
  - feature: email: can now set Reply-To (#540, Tim Meighen)
  - feature: mongodb: replica sets are supported (#389, patch by Mathias Gug)
  - new: s3: New plugin to write to amazon S3 (#439, patch by Mattia Peterle)
  - feature: statsd: now supports 'set' metrics (#513, patch by David Warden)
  - feature: sqs: now supports batching (#522, patch by AaronTheApe)
  - feature: ganglia: add slope and group settings (#583, patch by divanikus)

## 1.1.13 (May 28, 2013)
### general
  - fixed bug in static file serving for logstash web (LOGSTASH-1067)

### outputs
  - feature: irc: add messages_per_second tunable (LOGSTASH-962)

## 1.1.12 (May 7, 2013)
### filters
  - bugfix: useragent filter now works correctly with the built-in regexes.yaml
  - bugfix: mail output with smtp now works again

## 1.1.11 (May 7, 2013)
### general
  - This release is primarily a bugfix release for bugs introduced by the
    previous release.
  - Support for Rubinius and MRI exists once again.

### inputs
  - bugfix: lumberjack now respects field data again (lumberjack --field foo=bar)
  - bugfix: rabbitmq was broken by the previous release (LOGSTASH-1003,
    LOGSTASH-1038; Patch by Jason Koppe)
  - bugfix: relp: allow multiple client socket connections to RELP input
    (LOGSTASH-707, LOGSTASH-736, LOGSTASH-921)

### filters
  - bugfix: geoip was broken by the previous release (LOGSTASH-1013)
  - feature: sleep now accepts an 'every' setting which causes it to
    sleep every N events. Example; sleep every 10 events: every => 10.
  - feature: grok now permits dashes and dots in captures, such as
    %{WORD:foo-bar}.
  - bugfix: useragent filter now ships with a default regexes.yaml file
    that is used by default unless you otherwise specify (LOGSTASH-1051)
  - bugfix: add_field now correctly sets top-level fields like @message
  - bugfix: mutate 'replace' now sets a field regardless of whether or not
    it exists.
  - feature: new mutate 'update' setting to change a field's value but
    only if that field exists already.

### outputs
  - feature: irc output now supports 'secure' setting to use ssl (LOGSTASH-139)
  - feature: nagios_nsca has new setting 'message_format'
  - bugfix: fix graphite plugin broken in 1.1.10 (LOGSTASH-968)
  - bugfix: elasticsearch_http was broken in 1.1.10 (LOGSTASH-1004)
  - bugfix: rabbitmq was broken by the previous release (LOGSTASH-1003,
    LOGSTASH-1038; Patch by Jason Koppe)
  - feature: hipchat 'notify' setting now called 'trigger_notify' (#467, patch
    by Richard Pijnenburg)

## 1.1.10 (April 16, 2013)
### general
  - On linux, all threads will set their process names so you can identify
    threads in tools like top(1).
  - Java 5 is no longer supported (You must use Java 6 or newer).
  - Windows line terminators (CRLF) are now accepted in config files.
  - All AWS-related plugins now have the same configuration options:
    region, access_key_id, secret_access_key, use_ssl, and
    aws_credentials_file. Affected plugins: cloudwatch output,
    sns output, sqs output, sqs input. (LOGSTASH-805)
  - Lots of documentation fixes (James Turnbull, et al)
  - The amqp plugins are now named 'rabbitmq' because it *only* works
    with rabbitmq. The old 'amqp' name should still work, but it will
    be removed soon while 'rabbitmq' will stay. (Patches by Michael Zaccari)
  - New flag '--configtest' to test config and exit. (Patch by Darren Patterson)
  - Improved error feedback logstash gives to you as a user.

### inputs
  - new: elasticsearch: this input allows you to stream search results from
    elasticsearch; it uses the Scroll API.
  - new: websocket. Currently supports acting as a websocket client.
  - new: snmptrap, to receive SNMP traps (patch by Paul Czar)
  - new: varnishlog input to read from the Varnish Cache server's shared memory
    log (LOGSTASH-978, #422; Louis Zuckerman)
  - new: graphite input. Supports the plain text carbon tcp protocol.
  - new: imap input. Read mail!
  - feature: twitter: supports http proxying now (#276, patch by Richard
    Pijnenburg)
  - feature: loggly: supports http proxying now (#276, patch by Richard
    Pijnenburg)
  - feature: tcp: ssl now supported! (#318, patch by Matthew Richardson)
  - feature: redis: now supports 'batch_count' option for doing bulk fetches
    from redis lists. Requires Redis 2.6.0 or higher. (#320, patch by Piavlo)
  - feature: irc: will use ssl if you set 'secure' (#393, patch by Tomas Doran)
  - bugfix: log4j: respect add_fields (LOGSTASH-904, #358)
  - bugfix: eventlog: input should now work
  - bugfix: irc: passwords now work (#412, Nick Ethier)

### filters
  - new: useragent: parses user agent strings in to structured data based on
    BrowserScope data (#347, patch by Dan Everton)
  - new: sleep: sleeps a given amount of time before passing the event.
    Useful for rate limiting or replay simulation.
  - new: ruby: experimental ruby plugin that lets you call custom ruby code
    on every event.
  - new: translate: for mapping values (#335, patch by Paul Czar)
  - new: clone: creates a copy of the event.
  - feature: grok: Adds tag_on_failure setting so you can prevent grok from
    tagging events on failure. (#328, patch by Neil Prosser)
  - deprecated: grok: deprecated the --grok-patterns-path flag (LOGSTASH-803)
  - feature: date: nested field access is allowed now
  - feature: csv, xml, kv, json, geoip: new common settings!
    (LOGSTASH-756, #310, #311, #312, #383, #396; patches by Richard Pijnenburg)
      source - what field the text comes from
      target - where to store the parse result.
  - feature: csv: new setting: columns - labels for each column parsed.
  - bugfix: geoip: The built-in geoip database should work now (#326, patch
    by Vincent Batts)
  - bugfix: kv filter now respects add_tag, etc (LOGSTASH-935)

### outputs
  - new: hipchat output (#428, Cameron Stokes)
  - bugfix: mongo would fail to load bson_java support (LOGSTASH-849)
  - bugfix: tags support to gelf output. Returns tags as _tags field
    (LOGSTASH-880, patch by James Turnbull)
  - bugfix: elasticsearch: Fix a race condition. (#340, patch by Raymond Feng)
  - improvement: http: now supports a custom 'message' format for building your
    own http bodies from an event. (#319, patch by Christian S)
  - bugfix: Fix opentsdb output (LOGSTASH-689, #317; patch by Emmet Murphy)
  - improvement: http output now supports a custom message format with
    the 'message' setting (Patch by Christian Schröder)
  - graphite output now lets you ship the whole (or part) of an event's fields
    to graphite as metric updates. (#350, patch by Piavlo)
  - email output now correctly defaults to not using authentication
    (LOGSTASH-559, #365; patch by Stian Mathiassen)
  - bugfix: file output now works correctly on fifos
  - bugfix: irc passwords now work (#412, Nick Ethier)
  - improvement: redis output now supports congestion detection. If
    it appears nothing is consuming from redis, the output will stall
    until that problem is resolved. This helps prevent a dead reader
    from letting redis fill up memory. (Piavlo)
  - feature: boundary: New 'auto' setting. (#413, Alden Jole)

## 1.1.9 (January 10, 2013)
### inputs
  - bugfix: all inputs: fix bug where some @source values were not valid urls

### filters
  - bugfix: mutate: skip missing fields in 'convert' (#244, patch by Ralph Meijer)

### outputs
  - improvement: gelf: new tunable 'ignore_metadata' flag to set which fields
    to ignore if ship_metadata is set. (#244, patch by Ralph Meijer)
  - improvement: gelf: make short_message's field name tunable (#244, patch by
    Ralph Meijer)

## 1.1.8 (January 10, 2013)
### general
  - patched another work around for JRUBY-6970 (LOGSTASH-801)

### inputs
  - bugfix: tcp: 'Address in use' errors now report the host/port involved.
    (LOGSTASH-831)
  - bugfix: zeromq: fix bug where an invalid url could be given as a source
    (LOGSTASH-821, #306)

### outputs
  - bugfix: elasticsearch_river: it now resolves evaluates %{} variables in
    index and index_type settings. (LOGSTASH-819)

## 1.1.7 (January 3, 2013)
### inputs
 - fix bug where @source_host was set to 'false' in many cases.

### outputs
 - improvement: redis: shuffle_hosts is now enabled by default

## 1.1.6 (January 2, 2013)
### Overview of this release:
 - new inputs: drupal_dblog.
 - new filters: anonymize, metrics.
 - new outputs: syslog, cloudwatch.
 - new 'charset' setting for all inputs. This should resolve all known encoding
   problems. The default charset is UTF-8.
 - grok now captures (?<somename>...) regexp into 'somename' field
 - Elasticsearch 0.20.2 is included. This means you are required to upgrade
   your elasticsearch cluster to 0.20.2. If you wish to continue using an old
   version of elasticsearch, you should use the elasticsearch_http plugin
   instead of the elasticsearch one.

 ### general
 - fixed internal dependency versioning on 'addressable' gem (LOGSTASH-694)
 - fixed another case of 'watchdog timeout' (LOGSTASH-701)
 - plugin flags are now deprecated. The grok filter (--grok-pattern-path) was
   the only plugin to make use of this.
 - the grok filter has improved documentation
 - lots of documentation fixes (James Turnbull, Louis Zuckerman)
 - lots of testing improvements (Philippe Weber, Laust Rud Jacobsen)
 - all 'name' settings have been deprecated in favor of more descriptive
   settings (LOGSTASH-755)
 - JRuby upgraded to 1.7.1
 - removed use of bundler
 - Fixed timestamp parsing in MRI (patch by Rene Lengwinat)

 ### inputs
 - All inputs now have a 'charset' setting to help you inform logstash of the
   text encoding of the input. This is useful if you have Shift_JIS or CP1251
   encoded log files. This should help resolve the many UTF-8 bugs that were
   reported recently. The default charset is UTF-8.
 - new: drupal_dblog: read events from a DBLog-enabled Drupal. (#251, Patch by
   theduke)
 - bugfix: zeromq: 'topology' is now a required setting
 - bugfix: lumberjack: client connection closing is now handled properly.
   (Patch by Nick Ethier)
 - misc: lumberjack: jls-lumberjack gem updated to 0.0.7
 - bugfix: stomp: fix startup problems causing early termination (#226
 - bugfix: tcp: the 'source host' for events is now the client ip:port that
   sent it, instead of the listen address that received it. (LOGSTASH-796)
 - improvement: tcp: the default data_timeout is now -1 (never timeout).
   This change was made because read timeouts were causing data loss, and
   logstash should avoid losing events by default.
 - improvement: amqp: the 'name' setting is now called 'queue' (#274)
 - improvement: eventlog: the 'name' setting is now called 'logfile' (#274)
 - bugfix: log4j: fix stacktrace reading (#253, patch by Alex Arutyunyants)

 ### filters
 - new: anonymize: supports many hash mechanisms (murmur3, sha1, md5, etc) as
   well as IP address anonymization (#280, #261; patches by Richard Pijnenburg
   and Avishai Ish-Shalom)
 - new: metrics: allows you to aggregate metrics from events and emit them
   periodically. Think of this like 'statsd' but implemented as a logstash
   filter instead of an external service.
 - feature: date: now accepts 'match' as a setting. Use of this is preferable
   to the old syntax. Where you previously had 'date { somefield =>
   "somepattern" }' you should now do: 'date { match => [ "somefield",
   "somepattern" ] }'. (#248, LOGSTASH-734, Patch by Louis Zuckerman)
 - feature: grok: now accepts (?<foo>...) named captures. This lets you
   compose a pattern in the grok config without needing to define it in a
   patterns file. Example: (?<hostport>%{HOST}:%{POSINT}) to capture 'hostport'
 - improvement: grok: allow '$' in JAVACLASS pattern (#241, patch by Corry
   Haines)
 - improvement: grok: can now match against number types. Example, if you're
   sending a json format event with { "status": 403 } you can now grok that
   field.  The number is represented as a string "403" before pattern matching.
 - bugfix: date: Fix a bug that would crash the pipeline if no date pattern
   matched. (LOGSTASH-705)
 - feature: kv: Adds field_split, value_split, prefix, and container
   settings. (#225, patch by Alex Wheeler)
 - bugfix: mutate: rename on a nonexistent field now does nothing as expected.
   (LOGSTASH-757)
 - bugfix: grok: don't tag an event with _grokparsefailure if it's already so
   (#248, patch by Greg Brockman)
 - feature: mutate: new settings - split, join, strip. "split" splits a field
   into an array. "join" merges an array into a string. "strip" strips leading and
   trailing whitespace. (Patch by Avishai Ish-Shalom)

### outputs
 - new: syslog output supporting both RFC3164 and RFC5424 (#180, patch by
   Rui Alves)
 - new: cloudwatch output to emit metrics and other events to Amazon CloudWatch.
   (LOGSTASH-461, patch by Louis Zuckerman)
 - feature: stdout: added 'message' setting for configuring the output message
   format. The default is same behavior as before this feature.
 - feature: http: added 'format' option to select 'json' or form-encoded
   request body to send with each request.
 - feature: http: added 'content_Type' option set the Content-Type header.
   This defaults to "application/json" if the 'format' is 'json'. Will default
   to 'application/x-www-form-urlencoded' if the 'format' is 'form'
 - bugfix: zeromq: 'topology' is now a required setting
 - feature: mongodb: new setting 'isodate' that, when true, stores the
   @timestamp field as a mongodb date instead of a string. (#224, patch by
   Kevin Amorin)
 - improvement: gelf: Allow full_message gelf property to be overridden (#245,
   patch by Sébastien Masset)
 - misc: lumberjack: jls-lumberjack gem updated to 0.0.6
 - feature: nagios: New 'nagios_level' setting to let you change the level
   of the passive check result sent to nagios. (#298, Patch by James Turnbull)
 - feature: elasticsearch, elasticsearch_http, elasticsearch_river: new setting
   'document_id' for explicitly setting the document id in each write to
   elasticsearch. This is useful for overwriting existing documents.
 - improvement: elasticsearch_river: 'name' is now 'queue' (#274)
 - improvement: amqp: 'name' is now 'exchange' (#274)
 - bugfix: the websocket output works again (supports RFC6455)

## 1.1.5 (November 10, 2012)
### Overview of this release:
 * New inputs: zenoss, gemfire
 * New outputs: lumberjack, gemfire
 * Many UTF-8 crashing bugs were resolved

### general
 - new runner command 'rspec' - lets you run rspec tests from the jar
   This means you should now be able to write external tests that execute your
   logstash configs and verify functionality.
 - "file not found" errors related to paths that had "jar:" prefixes should
   now work. (Fixes LOGSTASH-649, LOGSTASH-642, LOGSTASH-655)
 - several plugins received UTF-8-related fixes (file, lumberjack, etc)
   File bugs if you see any UTF-8 related crashes.
 - 'json_event' format inputs will now respect 'tags' (#239, patch by
   Tim Laszlo)
 - logstash no longer uses nor recommends bundler (see 'gembag.rb'). The
   Gemfile will be purged in the near future.
 - amqp plugins are now marked 'unsupported' as there is no active maintainer
   nor is there source of active support in the community. If you're interested
   in maintainership, please email the mailing list or contact Jordan!

### inputs
 - irc: now stores irc nick
 - new: zenoss (#232, patch by Chet Luther)
 - new: gemfire (#235, patch by Andrea Campi)
 - bugfix: udp: skip close() call if we're already closed (#238, patch by kcrayon)

### filters
 - bugfix: fix for zeromq filter initializer (#237, patch by Tom Howe)

### outputs
 - new: lumberjack output (patch by Nick Ethier)
 - new: gemfire output (#234, patch by Andrea Campi)
 - improved: nagios_ncsa (patch by Tomas Doran)
 - improved: elasticsearch: permit setting 'host' even if embedded. Also set the
   host default to 'localhost' when using embedded. These fixes should help resolve
   issues new users have when their distros surprisingly block multicast by
   default.
 - improved: elasticsearch: failed index attempts will be retried
 - improved: irc: new 'password' setting (#283, patch by theduke)

## 1.1.4 (October 28, 2012)
### Overview of this release:
 - bug fixes mostly

### filters
 - date: Fix crashing on date filter failures. Wrote test to cover this case.
   (LOGSTASH-641)
 - grok: Improve QUOTEDSTRING pattern to avoid some more 'watchdog timeout' problems

### outputs
 - nagios_nsca: Allow check status to be set from the event (#228, patch by
   Tomas Doran)
 - elasticsearch_http: Fix OpenSSL::X509::StoreError (LOGSTASH-642)

## 1.1.3 (October 22, 2012)
 - rebuilt 1.1.2 for java 5 and 6

## 1.1.2 (October 22, 2012)
### Overview of this release:
  * New input plugins: lumberjack, sqs, relp
  * New output plugins: exec, sqs
  * New filter plugins: kv, geoip, urldecode, alter
  * file input supports backfill via 'start_position'
  * filter watchdog timer set to 10 seconds (was 2 seconds)

### general
 - Stopped using 'Gemfile' for dependencies, the logstash.gemspec has returned.
   (Patch by Grant Rogers)
 - New 'logstash-event.gemspec' for generating logstash events in your own
   ruby programs (Patch by Garry Shutler)
 - Wildcard config files are now sorted properly (agent -f
   /etc/logstash/*.conf)
 - The old '-vvv' setting ruby's internal $DEBUG is now gone. It was causing
   too much confusion for users due to noise.
 - Improved 'logstash event' creation speed by 3.5x
 - Now uses JRuby 1.7.0
 - Now ships with Elasticsearch 0.19.10

### inputs
 - bugfix: redis: [LOGSTASH-526] fix bug with password passing
 - new: lumberjack: for use with the lumberjack log shipper
   (https://github.com/jordansissel/lumberjack)
 - new: sqs: Amazon SQS input (Patch by Sean Laurent, #211)
 - new: relp: RELP (rsyslog) plugin (Patch by Mike Worth, #177)
 - file input: sincedb path is now automatically generated if not specified.
   This helps work around a problem where two file inputs don't specify a
   sincedb_path would clobber eachother (LOGSTASH-554)
 - file input: no longer crashes if HOME is not set in env (LOGSTASH-458)
 - log4j input: now supports MDC 'event properties' which are stored as fields
   in the logstash event. (#216, #179. Patches by Charles Robertson and Jurjan
   Woltman)
 - pipe input: should work now.

### filters
 - new: kv: useful for parsing log formats taht use 'foo=bar baz=fizz' and
   similar key-value-like things.
 - new: urldecode: a filter for urldecoding fields in your event. (Patch by
   Joey Imbasciano, LOGSTASH-612)
 - new: geoip: query a local geoip database for location information (Patch by
   Avishai Ish-Shalom, #208)
 - improvement: zeromq: an empty reply is now considered as a 'cancel this
   event' operation (LOGSTASH-574)
 - bugfix: mutate: fix bug in uppercase and lowercase feature that would
   prevent it from actually doing the uppercasing/lowercasing.
 - improvement: mutate: do the 'remove' action last (LOGSTASH-543)
 - feature: grok: new 'singles' config option which, when true, stores
   single-value fields simply as a single value rather than as an array, like
   [value]. (LOGSTASH-185)
 - grok patterns: the URIPARAM pattern now includes pipe '|' as a valid
   character. (Patch by Chris Mague)
 - grok patterns: improve haproxy log patterns (Patch by Kevin Nuckolls)
 - grok patterns: include 'FATAL' as a valid LOGLEVEL match
   (patch by Corry Haines)
 - grok patterns: 'ZONE' is no longer captured by name in the HTTPDATE pattern
 - new: alter: adds some conditional field modification as well as a
   'coalesce' feature which sets the value of a field to the first non-null
   value given in a list. (Patch by Francesco Salbaroli)
 - improvement: date: add TAI64N support
 - improvement: date: subsecond precision on UNIX timestamps is retained on
   conversion (#213, Patch by Ralph Meijer)
 - improvement: date: Add locale setting; useful for day/month name parsing.
   (#100, Patch by Christian Schröder)

### outputs
 - new: exec: run arbitrary commands based on an event.
 - new: sqs: Amazon SQS output (Patch by Sean Laurent, #211)
 - bugfix: redis: [LOGSTASH-526] fix bug with password passing
 - improvement: redis: [LOGSTASH-573] retry on failure even in batch-mode. This
   also fixes a prior bug where an exception in batch mode would cause logstash
   to crash. (Patch by Alex Dean)
 - improvement: riemann: metric and ttl values in riemann_event now support
   sprintf %{foo} values. (pull #174)
 - improvement: stdout: new 'dots' debug_format value emits one dot per event
   useful for tracking event rates.
 - gelf output: correct severity level mappings (patch by Jason Koppe)
 - xmpp output: users and rooms are separate config settings now (patch by
   Parker DeBardelaben)
 - improvement: redis: 'host' setting now accepts a list of hosts for failover
   of writes should the current host go down. (#222, patch by Corry Haines)

##1.1.1 (July 14, 2012)
### Overview of this release:
  * New input plugins: generator, heroku, pipe, ganglia, irc
  * New output plugins: juggernaut, metricscatcher, nagios_ncsa, pipe,
                        opentsdb, pagerduty, irc
  * New filter plugins: zeromq, environment, xml, csv, syslog_pri
  * Fixes for gelf output
  * Support for more than 1 filter worker (agent argument "-w")

### IMPORTANT CHANGES FOR UPGRADES FROM 1.1.0
  - zeromq input and output rewritten
      The previous zeromq support was an MVP. It has now been rewritten into
      something more flexible. The configuration options have changed entirely.
      While this is still listed as `experimental`, we don't predict any more
      configuration syntax changes. The next release will bump this to beta.
  - unix_timestamp
      Previously, several plugins did not work as expected on MRI due to the
      usage of the JRuby-only Jodatime library. We now have a contributed fix
      for a slower parser on MRI/CRuby!
  - elasticsearch version is now 0.19.8
      This means your elasticsearch cluster must be running 0.19.x for
      compatibility reasons.
  - grok pattern %{POSINT} used to match '0' -- now it does not. If you want
    to match non-negative integers, there is now a %{NONNEGINT} pattern.
  - bug in file input fixed that led to an extra leading slash in @source_path.
    Previously, file input would have @source = 'file://host//var/log/foo' and
    @source_path = '//var/log/foo'; now @source = 'file://host/var/log/foo'
    and @source_path = '/var/log/foo'. [LOGSTASH-501]
  - file input now rejects relative paths. [LOGSTASH-503]
  - event sprintf can now look inside structured field data. %{foo.bar} will
    look in the event field "foo" (if it is a hash) for "bar".  To preserve
    compatibility, we first look for a top-level key that matches exactly
    (so %{foo.bar} will first look for a field named "foo.bar", then look for
    "bar" under "foo").

### general
  - NOTE: gemspec removed; deploying logstash as a gem hasn't been supported
    for a while.
  - feature: logstash sub-commands "irb" and "pry" for an interactive debug
    console, useful to debug jruby when running from the monolithic jar
  - misc: newer cabin gem for logging
  - misc: initial support for reporting internal metrics (currently outputs
    to INFO log; eventually will be an internal event type)
  - misc: added a "thread watchdog" to detect hanging filter workers, and
    crash logstash w/an informational message
  - misc: jar is built with jruby 1.6.7.2
  - misc: better shutdown behavior when there are no inputs/plugins running
  - feature: logstash web now uses relative URLs; useful if you want to
    reverseproxy with a path other than "/"

### inputs
  - bugfix: stdin: exit plugin gracefully on EOF
  - feature: [LOGSTASH-410] - inputs can now be duplicated with the
    'threads' parameter (where supported)
  - bugfix: [LOGSTASH-490] - include cacert.pem in jar for twitter input
  - feature: [LOGSTASH-139] - support for IRC

### filters
  - feature: all filters support 'remove_tag' (remove tags on success)
  - feature: all filters support 'exclude_tags' (inverse of 'tags')
  - bugfix: [LOGSTASH-300] - bump grok pattern replace limit to 1000,
    fixes "deep recursion pattern compilation" problems
  - bugfix: [LOGSTASH-375] - fix bug in grep: don't drop when field is nil
    and negate is true
  - bugfix: [LOGSTASH-386] - fix some grok patterns for haproxy
  - bugfix: [LOGSTASH-446] - fix grok %{QUOTEDSTRING} pattern, should fix
    some grok filter hangs
  - bugfix: some enhancements to grok pattern %{COMBINEDAPACHELOG}
  - bugfix: grok: %{URIPATH} and %{URIPARAM} enhancements
  - feature: grok: add %{UUID} pattern
  - bugfix: grok: better error message when expanding unknown %{pattern}
  - feature: mutate: now supports a 'gsub' operation for applying a regexp
    substitution on event fields

### outputs
  - bugfix: [LOGSTASH-351] - fix file input on windows
  - feature: [LOGSTASH-356] - make file output flush intervals configurable
  - feature: [LOGSTASH-392] - add 'field' attribute to restrict which fields
    get sent to an output
  - feature: [LOGSTASH-374] - add gzip support to file output
  - bugfix: elastic search river now respects exchange_type and queue_name
  - bugfix: ganglia plugin now respects metric_type
  - bugfix: GELF output facility fixes; now defaults to 'logstash-gelf'
  - feature: [LOGSTASH-139] - support for IRC
  - bugfix: es_river: check river status after creation to verify status
  - feature: es: allow setting node_name
  - feature: redis: output batching for list mode

## 1.1.0.1 (January 30, 2012)
### Overview of this release:
    * date filter bugfix: [LOGSTASH-438] - update joda-time to properly
      handle leap days

### 1.1.0 (January 30, 2012)
  ## Overview of this release:
    * New input plugins: zeromq, gelf
    * New filter plugins: mutate, dns, json
    * New output plugins: zeromq, file
    * The logstash agent now runs also in MRI 1.9.2 and above

    This is a large release due to the longevity of the 1.1.0 betas.
    We don't like long releases and will try to avoid this in the future.

### IMPORTANT CHANGES FOR UPGRADES FROM 1.0.x
    - grok filter: named_captures_only now defaults to true
        This means simple patterns %{NUMBER} without any other name will
        now not be included in the field set. You can revert to the old
        behavior by setting 'named_captures_only => false' in your grok
        filter config.
    - grok filter: now uses Ruby's regular expression engine
        The previous engine was PCRE. It is now Oniguruma (Ruby). Their
        syntaxes are quite similar, but it is something to be aware of.
    - elasticsearch library upgraded to 0.18.7
        This means you will need to upgrade your elasticsearch servers,
        if any, to the this version: 0.18.7
    - AMQP parameters and usage have changed for the better. You might
      find that your old (1.0.x) AMQP logstash configs do not work.
      If so, please consult the documentation for that plugin to find
      the new names of the parameters.

### general
  - feature: [LOGSTASH-158] - MRI-1.9 compatible (except for some
    plugins/functions which will throw a compatibility exception) This means
    you can use most of the logstash agent under standard ruby.
  - feature: [LOGSTASH-118] - logstash version output (--version or -V for
    agent)
  - feature: all plugins now have a 'plugin status' indicating the expectation
    of stability, successful deployment, and rate of code change. If you
    use an unstable plugin, you will now see a warning message on startup.
  - bugfix: AMQP overhaul (input & output), please see docs for updated
    config parameters.
  - bugfix: [LOGSTASH-162,177,196] make sure plugin-contained global actions
    happen serially across all plugins (with a mutex)
  - bugfix: [LOGSTASH-286] - logstash agent should not truncate logfile on
    startup
  - misc: [LOGSTASH-160] - now use gnu make instead of rake.
  - misc: now using cabin library for all internal logging
  - test: use minitest
  - upgrade: now using jruby in 1.9 mode

### inputs
  - feature: zeromq input. Requires you have libzmq installed on your system.
  - feature, bugfix: [LOGSTASH-40,65,234,296]: much smarter file watching for
    file inputs. now supports globs, keeps state between runs, can handle
    truncate, log rotation, etc. no more inotify is required, either (file
    input now works on all platforms)
  - feature: [LOGSTASH-172,201] - syslog input accepts ISO8601 timestamps
  - feature: [LOGSTASH-159] - TCP input lets you configure what identifies
    an input stream to the multiline filter (unique per host, or connection)
  - feature: [LOGSTASH-168] - add new GELF input plugin
  - bugfix: [LOGSTASH-8,233] - fix stomp input
  - bugfix: [LOGSTASH-136,142] - file input should behave better with log rotations
  - bugfix: [LOGSTASH-249] - Input syslog force facility type to be an integer
  - bugfix: [LOGSTASH-317] - fix file input not to crash when a file
    is unreadable

### filters
  - feature: [LOGSTASH-66,150]: libgrok re-written in pure ruby (no more
    FFI / external libgrok.so dependency!)
  - feature: [LOGSTASH-292,316] - Filters should run on all events if no condition
    is applied (type, etc).
  - feature: [LOGSTASH-292,316] - Filters can now act on specific tags (or sets
    of tags).
  - bugfix: [LOGSTASH-285] - for grok, add 'keep_empty_captures' setting to
    allow dropping of empty captures. This is true by default.
  - feature: [LOGSTASH-219] - support parsing unix epoch times
  - feature: [LOGSTASH-207] - new filter to parse a field as json merging it
    into the event.
  - feature: [LOGSTASH-267,254] - add DNS filter for doing forward or
    reverse DNS on an event field
  - feature: [LOGSTASH-57] - add mutate filter to help with manipulating
    event field content and type

### outputs
  - feature: zeromq output. Requires you have libzmq installed on your system.
  - feature: new file output plugin
  - bugfix: [LOGSTASH-307] embedded elasticsearch now acts as a full ES server;
    previously embedded was only accessible from within the logstash process.
  - bugfix: [LOGSTASH-302] - logstash's log level (-v, -vv flags) now control
    the log output from the elasticsearch client via log4j.
  - bugfix: many gelf output enhancements and bugfixes
  - feature: [LOGSTASH-281] - add https support to loggly output
  - bugfix: [LOGSTASH-167] - limit number of in-flight requests to the
    elasticsearch node to avoid creating too many threads (one thread per
    pending write request)
  - bugfix: [LOGSTASH-181] - output/statsd: set sender properly
  - bugfix: [LOGSTASH-173] - GELF output can throw an exception during gelf notify
  - bugfix: [LOGSTASH-182] - grep filter should act on all events if no type is
    specified.
  - bugfix: [LOGSTASH-309] - file output can now write to named pipes (fifo)


## 1.0.17 (Aug 12, 2011)
  - Bugs fixed
    - [LOGSTASH-147] - grok filter incorrectly adding fields when a match failed
    - [LOGSTASH-151] - Fix bug in routing keys on AMQP
    - [LOGSTASH-156] - amqp issue with 1.0.16?

  - Improvement
    - [LOGSTASH-148] - AMQP input should allow queue name to be specified separately from exchange name
    - [LOGSTASH-157] - Plugin doc generator should make regexp config names more readable

  - New Feature
    - [LOGSTASH-153] - syslog input: make timestamp an optional field
    - [LOGSTASH-154] - Make error reporting show up in the web UI

## 1.0.16 (Aug 18, 2011)
  - Fix elasticsearch client problem with 1.0.15 - jruby-elasticsearch gem
    version required is now 0.0.10 (to work with elasticsearch 0.17.6)

## 1.0.15 (Aug 18, 2011)
  - IMPORTANT: Upgraded to ElasticSearch 0.17.6 - this brings a number of bug
    fixes including an OOM error caused during high index rates in some
    conditions.
    NOTE: You *must* use same main version of elasticsearch as logstash does,
    so if you are still using elasticsearch server 0.16.x - you need to upgrade
    your server before the elasticsearch output will work. If you are using
    the 'embedded' elasticsearch feature of logstash, you do not need to make
    any changes.
  - feature: tcp input and output plugins can now operate in either client
    (connect) or server (listen) modes.
  - feature: new output plugin "statsd" which lets you increment or record
    timings from your logs to a statsd agent
  - feature: new redis 'pattern_channel' input support for PSUBSCRIBE
  - feature: new output plugin "graphite" for taking metrics from events and
    shipping them off to your graphite/carbon server.
  - feature: new output plugin "ganglia" for shipping metrics to ganglia
    gmond server.
  - feature: new output plugin "xmpp" for shipping events over jabber/xmpp
  - feature: new input plugin "xmpp" for receiving events over jabber/xmpp
  - feature: amqp input now supports routing keys.
    https://logstash.jira.com/browse/LOGSTASH-122
  - feature: amqp output now supports setting routing key dynamically.
    https://logstash.jira.com/browse/LOGSTASH-122
  - feature: amqp input/output both now support SSL.
    https://logstash.jira.com/browse/LOGSTASH-131
  - feature: new input plugin "exec" for taking events from executed commands
    like shell scripts or other tools.
  - feature: new filter plugin "split" for splitting one event into multiple.
    It was written primarily for the new "exec" input to allow you to split
    the output of a single command run by line into multiple events.
  - misc: upgraded jar releases to use JRuby 1.6.3
  - bugfix: syslog input shouldn't crash anymore on weird network behaviors
    like portscanning, etc.
    https://logstash.jira.com/browse/LOGSTASH-130

## 1.0.14 (Jul 1, 2011)
  - feature: new output plugin "loggly" which lets you ship logs to loggly.com
  - feature: new output plugin "zabbix" - similar to the nagios output, but
    works with the Zabbix monitoring system. Contributed by Johan at
    Mach Technology.
  - feature: New agent '-e' flag which lets you specify a config in a string.
    If you specify no 'input' plugins, default is stdin { type => stdin }
    If you specify no 'output' plugins, default is stdout { debug => true }
    This is intended to be used for hacking with or debugging filters, but
    you can specify an entire config here if you choose.
  - feature: Agent '-f' flag now supports directories and globs. If you specify
    a directory, all files in that directory will be loaded as a single config.
    If you specify a glob, all files matching that glob will be loaded as a
    single config.
  - feature: gelf output now allows you to override the 'sender'. This defaults
    to the source host originating the event, but can be set to anything now.
    It supports dynamic values, so you can use fields from your event as the
    sender. Contributed by John Vincent
    Issue: https://github.com/logstash/logstash/pull/30
  - feature: added new feature to libgrok that allows you to define patterns
    in-line, like "%{FOO=\d+}" defines 'FOO' match \d+ and captures as such.
    To use this new feature, you must upgrade libgrok to at least 1.20110630
    Issue: https://logstash.jira.com/browse/LOGSTASH-94
  - feature: grok filter now supports 'break_on_match' defaulting to true
    (this was the original behavior). If you set it to false, it will attempt
    to match all patterns and create new fields as normal. If left default
    (true), it will break after the first successful match.
  - feature: grok filter now supports parsing any field. You can do either of
    these: grok { match => [ "fieldname", "pattern" ] }
    or this: grok { fieldname => "pattern" }
    The older 'pattern' attribute still means the same thing, and is equivalent
    to this: grok { match => [ "@message", "pattern" ] }
    Issue: https://logstash.jira.com/browse/LOGSTASH-101
  - feature: elasticsearch - when embedded is true, you can now set the
    'embedded_http_port' to configure which port the embedded elasticsearch
    server listens on. This is only valid for the embedded elasticsearch
    configuration. https://logstash.jira.com/browse/LOGSTASH-117
  - bugfix: amqp input now reconnects properly when the amqp broker restarts.
  - bugfix: Fix bug in gelf output when a fields were not arrays but numbers.
    Issue: https://logstash.jira.com/browse/LOGSTASH-113
  - bugfix: Fix a bug in syslog udp input due to misfeatures in Ruby's URI
    class. https://logstash.jira.com/browse/LOGSTASH-115
  - misc: jquery and jquery ui now ship with logstash; previously they were
    loaded externally
  - testing: fixed some bugs in the elasticsearch test itself, all green now.
  - testing: fixed logstash-test to now run properly

## 1.0.12 (Jun 9, 2011)
  - misc: clean up some excess debugging output
  - feature: for tcp input, allow 'data_timeout => -1' to mean "never time out"

## 1.0.11 (Jun 9, 2011)
  - deprecated: The redis 'name' and 'queue' options for both input and output
    are now deprecated. They will be removed in a future version.
  - feature: The redis input and output now supports both lists and channels.
  - feature: Refactor runner to allow you to run multiple things in a single
    process.  You can end each instance with '--' flag. For example, to run one
    agent and one web instance:
      % java -jar logstash-blah.jar agent -f myconfig -- web
  - feature: Add 'embedded' option to the elasticsearch output:
      elasticsearch { embedded => true }
    Default is false. If true, logstash will run an elasticsearch server
    in the same process as logstash. This is really useful if you are just
    starting out or only need one one elasticsearch server.
  - feature: Added a logstash web backend feature for elasticsearch that tells
    logstash to use the 'local' (in process) elasticsearch:
      --backend elasticsearch:///?local
  - feature: Added 'named_captures_only' option to grok filter. This will have
    logstash only keep the captures you give names to - for example %{NUMBER}
    won't be kept, but %{NUMBER:bytes} will be.
  - feature: Add 'bind_host' option to elasticsearch output. This lets you choose the
    address ElasticSearch client uses to bind to - useful if you have a
    multihomed server.
  - feature: The mongodb output now supports authentication
  - bugfix: Fix bug in GELF output that caused the gelf short_message to be set as an
    array if it came from a grok value. The short_message field should only
    now be a string properly.
  - bugfix: Fix bug in grep filter that would drop/cancel events if you had
    more than one event type flowing through filters and didn't have a grep
    filter defined for each type.
  - misc: Updated gem dependencies (tests still pass)
  - misc: With the above two points, you can now run a single logstash process
    that includes elasticsearch server, logstash agent, and logstash web.

## 1.0.10 (May 23, 2011)
  - Fix tcp input bug (LOGSTASH-88) that would drop connections.
  - Grok patterns_dir (filter config) and --grok-patterns-dir (cmdline opt)
    are now working.
  - GELF output now properly sends extra fields from the log event (prefixed
    with a "_") and sets timestamp to seconds-since-epoch (millisecond
    precision and time zone information is lost, but this is the format GELF
    asks for).
  - Inputs support specifying the format of input data (see "format" and
    "message_format" input config parameters).
  - Grok filter no longer incorrectly tags _grokparsefailure when more than
    one grok filter is enabled (for multiple types) or when an event has
    no grok configuration for it's type.
  - Fix bug where an invalid HTTP Referer: would break grok parsing of the
    log line (used to expect %{URI}). Since Referer: is not sanitized in
    the HTTP layer, we cannot assume it will be a well formed %{URI}.

## 1.0.9 (May 18, 2011)
  - Fix crash bug caused by refactoring that left 'break' calls in code
    that no longer used loops.

## 1.0.8 (May 17, 2011)
  - Remove beanstalk support because the library (beanstalk-client) is GPL3. I
    am not a lawyer, but I'm not waiting around to have someone complain about
    license incompatibilities.
  - fix bug in jar build

## 1.0.7 (May 16, 2011)
  - logstash 'web' now allows you to specify the elasticsearch clustername;
    --backend elasticsearch://[host[:port]]/[clustername]
  - GELF output now supports dynamic strings for level and facility
    https://logstash.jira.com/browse/LOGSTASH-83
  - 'amqp' output supports persistent messages over AMQP, now. Tunable.
    https://logstash.jira.com/browse/LOGSTASH-81
  - Redis input and output are now supported. (Contributed by dokipen)
  - Add shutdown processing. Shutdown starts when all inputs finish (like
    stdin) The sequence progresses using the same pipeline as the
    inputs/filters/outputs, so all in-flight events should finish getting
    processed before the final shutdown event makes it's way to the outputs.
  - Add retries to unhandled input exceptions (LOGSTASH-84)

## 1.0.6 (May 11, 2011)
  * Remove 'sigar' from monolithic jar packaging. This removes a boatload of
    unnecessary warning messages on startup whenever you use elasticsearch
    output or logstash-web.
    Issue: https://logstash.jira.com/browse/LOGSTASH-79

## 1.0.5 (May 10, 2011)
  * fix queues when durable is set to true

## 1.0.4 (May 9, 2011)
  * Fix bugs in syslog input

## 1.0.2 (May 8, 2011)
  * Fix default-value handling for configs when the validation type is
    'password'

## 1.0.1 (May 7, 2011)
  * Fix password auth for amqp and stomp (Reported by Luke Macken)
  * Fix default elasticsearch target for logstash-web (Reported by Donald Gordon)

## 1.0.0 (May 6, 2011)
  * First major release.
