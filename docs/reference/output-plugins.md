---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/output-plugins.html
---

# Output plugins [output-plugins]

An output plugin sends event data to a particular destination. Outputs are the final stage in the event pipeline.

The following output plugins are available below. For a list of Elastic supported plugins, please consult the [Support Matrix](https://www.elastic.co/support/matrix#show_logstash_plugins).

|     |     |     |
| --- | --- | --- |
| Plugin | Description | Github repository |
| [app_search (deprecated)](/reference/plugins-outputs-elastic_app_search.md) | [deprecated at {{stack}} version 9.0.0 and plugin version 3.0.1] Sends events to Elastic App Search | [logstash-integration-elastic_enterprise_search](https://github.com/logstash-plugins/logstash-output-elastic_app_search) |
| [boundary](/reference/plugins-outputs-boundary.md) | Sends annotations to Boundary based on Logstash events | [logstash-output-boundary](https://github.com/logstash-plugins/logstash-output-boundary) |
| [circonus](/reference/plugins-outputs-circonus.md) | Sends annotations to Circonus based on Logstash events | [logstash-output-circonus](https://github.com/logstash-plugins/logstash-output-circonus) |
| [cloudwatch](/reference/plugins-outputs-cloudwatch.md) | Aggregates and sends metric data to AWS CloudWatch | [logstash-output-cloudwatch](https://github.com/logstash-plugins/logstash-output-cloudwatch) |
| [csv](/reference/plugins-outputs-csv.md) | Writes events to disk in a delimited format | [logstash-output-csv](https://github.com/logstash-plugins/logstash-output-csv) |
| [datadog](/reference/plugins-outputs-datadog.md) | Sends events to DataDogHQ based on Logstash events | [logstash-output-datadog](https://github.com/logstash-plugins/logstash-output-datadog) |
| [datadog_metrics](/reference/plugins-outputs-datadog_metrics.md) | Sends metrics to DataDogHQ based on Logstash events | [logstash-output-datadog_metrics](https://github.com/logstash-plugins/logstash-output-datadog_metrics) |
| [dynatrace](/reference/plugins-outputs-dynatrace.md) | Sends events to Dynatrace based on Logstash events | [logstash-output-dynatrace](https://github.com/dynatrace-oss/logstash-output-dynatrace) |
| [elastic_app_search (deprecated)](/reference/plugins-outputs-elastic_app_search.md) | [deprecated at {{stack}} version 9.0.0 and plugin version 3.0.1]Sends events to the [Elastic App Search](https://www.elastic.co/app-search/) solution | [logstash-integration-elastic_enterprise_search](https://github.com/logstash-plugins/logstash-output-elastic_app_search) |
| [elastic_workplace_search](/reference/plugins-outputs-elastic_workplace_search.md) | Sends events to the [Elastic Workplace Search](https://www.elastic.co/enterprise-search) solution | [logstash-integration-elastic_enterprise_search](https://github.com/logstash-plugins/logstash-output-elastic_app_search) |
| [elasticsearch](/reference/plugins-outputs-elasticsearch.md) | Stores logs in Elasticsearch | [logstash-output-elasticsearch](https://github.com/logstash-plugins/logstash-output-elasticsearch) |
| [email](/reference/plugins-outputs-email.md) | Sends email to a specified address when output is received | [logstash-output-email](https://github.com/logstash-plugins/logstash-output-email) |
| [exec](/reference/plugins-outputs-exec.md) | Runs a command for a matching event | [logstash-output-exec](https://github.com/logstash-plugins/logstash-output-exec) |
| [file](/reference/plugins-outputs-file.md) | Writes events to files on disk | [logstash-output-file](https://github.com/logstash-plugins/logstash-output-file) |
| [ganglia](/reference/plugins-outputs-ganglia.md) | Writes metrics to Ganglia’s `gmond` | [logstash-output-ganglia](https://github.com/logstash-plugins/logstash-output-ganglia) |
| [gelf](/reference/plugins-outputs-gelf.md) | Generates GELF formatted output for Graylog2 | [logstash-output-gelf](https://github.com/logstash-plugins/logstash-output-gelf) |
| [google_bigquery](/reference/plugins-outputs-google_bigquery.md) | Writes events to Google BigQuery | [logstash-output-google_bigquery](https://github.com/logstash-plugins/logstash-output-google_bigquery) |
| [google_cloud_storage](/reference/plugins-outputs-google_cloud_storage.md) | Uploads log events to Google Cloud Storage | [logstash-output-google_cloud_storage](https://github.com/logstash-plugins/logstash-output-google_cloud_storage) |
| [google_pubsub](/reference/plugins-outputs-google_pubsub.md) | Uploads log events to Google Cloud Pubsub | [logstash-output-google_pubsub](https://github.com/logstash-plugins/logstash-output-google_pubsub) |
| [graphite](/reference/plugins-outputs-graphite.md) | Writes metrics to Graphite | [logstash-output-graphite](https://github.com/logstash-plugins/logstash-output-graphite) |
| [graphtastic](/reference/plugins-outputs-graphtastic.md) | Sends metric data on Windows | [logstash-output-graphtastic](https://github.com/logstash-plugins/logstash-output-graphtastic) |
| [http](/reference/plugins-outputs-http.md) | Sends events to a generic HTTP or HTTPS endpoint | [logstash-output-http](https://github.com/logstash-plugins/logstash-output-http) |
| [influxdb](/reference/plugins-outputs-influxdb.md) | Writes metrics to InfluxDB | [logstash-output-influxdb](https://github.com/logstash-plugins/logstash-output-influxdb) |
| [irc](/reference/plugins-outputs-irc.md) | Writes events to IRC | [logstash-output-irc](https://github.com/logstash-plugins/logstash-output-irc) |
| [java_stdout](/reference/plugins-outputs-java_stdout.md) | Prints events to the STDOUT of the shell | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/outputs/Stdout.java) |
| [juggernaut](/reference/plugins-outputs-juggernaut.md) | Pushes messages to the Juggernaut websockets server | [logstash-output-juggernaut](https://github.com/logstash-plugins/logstash-output-juggernaut) |
| [kafka](/reference/plugins-outputs-kafka.md) | Writes events to a Kafka topic | [logstash-integration-kafka](https://github.com/logstash-plugins/logstash-integration-kafka) |
| [librato](/reference/plugins-outputs-librato.md) | Sends metrics, annotations, and alerts to Librato based on Logstash events | [logstash-output-librato](https://github.com/logstash-plugins/logstash-output-librato) |
| [loggly](/reference/plugins-outputs-loggly.md) | Ships logs to Loggly | [logstash-output-loggly](https://github.com/logstash-plugins/logstash-output-loggly) |
| [logstash](/reference/plugins-outputs-logstash.md) | Ships data to {{ls}} input on another {{ls}} instance | [logstash-integration-logstash](https://github.com/logstash-plugins/logstash-integration-logstash) |
| [lumberjack](/reference/plugins-outputs-lumberjack.md) | Sends events using the `lumberjack` protocol | [logstash-output-lumberjack](https://github.com/logstash-plugins/logstash-output-lumberjack) |
| [metriccatcher](/reference/plugins-outputs-metriccatcher.md) | Writes metrics to MetricCatcher | [logstash-output-metriccatcher](https://github.com/logstash-plugins/logstash-output-metriccatcher) |
| [mongodb](/reference/plugins-outputs-mongodb.md) | Writes events to MongoDB | [logstash-output-mongodb](https://github.com/logstash-plugins/logstash-output-mongodb) |
| [nagios](/reference/plugins-outputs-nagios.md) | Sends passive check results to Nagios | [logstash-output-nagios](https://github.com/logstash-plugins/logstash-output-nagios) |
| [nagios_nsca](/reference/plugins-outputs-nagios_nsca.md) | Sends passive check results to Nagios using the NSCA protocol | [logstash-output-nagios_nsca](https://github.com/logstash-plugins/logstash-output-nagios_nsca) |
| [opentsdb](/reference/plugins-outputs-opentsdb.md) | Writes metrics to OpenTSDB | [logstash-output-opentsdb](https://github.com/logstash-plugins/logstash-output-opentsdb) |
| [pagerduty](/reference/plugins-outputs-pagerduty.md) | Sends notifications based on preconfigured services and escalation policies | [logstash-output-pagerduty](https://github.com/logstash-plugins/logstash-output-pagerduty) |
| [pipe](/reference/plugins-outputs-pipe.md) | Pipes events to another program’s standard input | [logstash-output-pipe](https://github.com/logstash-plugins/logstash-output-pipe) |
| [rabbitmq](/reference/plugins-outputs-rabbitmq.md) | Pushes events to a RabbitMQ exchange | [logstash-integration-rabbitmq](https://github.com/logstash-plugins/logstash-integration-rabbitmq) |
| [redis](/reference/plugins-outputs-redis.md) | Sends events to a Redis queue using the `RPUSH` command | [logstash-output-redis](https://github.com/logstash-plugins/logstash-output-redis) |
| [redmine](/reference/plugins-outputs-redmine.md) | Creates tickets using the Redmine API | [logstash-output-redmine](https://github.com/logstash-plugins/logstash-output-redmine) |
| [riak](/reference/plugins-outputs-riak.md) | Writes events to the Riak distributed key/value store | [logstash-output-riak](https://github.com/logstash-plugins/logstash-output-riak) |
| [riemann](/reference/plugins-outputs-riemann.md) | Sends metrics to Riemann | [logstash-output-riemann](https://github.com/logstash-plugins/logstash-output-riemann) |
| [s3](/reference/plugins-outputs-s3.md) | Sends Logstash events to the Amazon Simple Storage Service | [logstash-output-s3](https://github.com/logstash-plugins/logstash-output-s3) |
| [sink](/reference/plugins-outputs-sink.md) | Discards any events received | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/outputs/Sink.java) |
| [sns](/reference/plugins-outputs-sns.md) | Sends events to Amazon’s Simple Notification Service | [logstash-output-sns](https://github.com/logstash-plugins/logstash-output-sns) |
| [solr_http](/reference/plugins-outputs-solr_http.md) | Stores and indexes logs in Solr | [logstash-output-solr_http](https://github.com/logstash-plugins/logstash-output-solr_http) |
| [sqs](/reference/plugins-outputs-sqs.md) | Pushes events to an Amazon Web Services Simple Queue Service queue | [logstash-output-sqs](https://github.com/logstash-plugins/logstash-output-sqs) |
| [statsd](/reference/plugins-outputs-statsd.md) | Sends metrics using the `statsd` network daemon | [logstash-output-statsd](https://github.com/logstash-plugins/logstash-output-statsd) |
| [stdout](/reference/plugins-outputs-stdout.md) | Prints events to the standard output | [logstash-output-stdout](https://github.com/logstash-plugins/logstash-output-stdout) |
| [stomp](/reference/plugins-outputs-stomp.md) | Writes events using the STOMP protocol | [logstash-output-stomp](https://github.com/logstash-plugins/logstash-output-stomp) |
| [syslog](/reference/plugins-outputs-syslog.md) | Sends events to a `syslog` server | [logstash-output-syslog](https://github.com/logstash-plugins/logstash-output-syslog) |
| [tcp](/reference/plugins-outputs-tcp.md) | Writes events over a TCP socket | [logstash-output-tcp](https://github.com/logstash-plugins/logstash-output-tcp) |
| [timber](/reference/plugins-outputs-timber.md) | Sends events to the Timber.io logging service | [logstash-output-timber](https://github.com/logstash-plugins/logstash-output-timber) |
| [udp](/reference/plugins-outputs-udp.md) | Sends events over UDP | [logstash-output-udp](https://github.com/logstash-plugins/logstash-output-udp) |
| [webhdfs](/reference/plugins-outputs-webhdfs.md) | Sends Logstash events to HDFS using the `webhdfs` REST API | [logstash-output-webhdfs](https://github.com/logstash-plugins/logstash-output-webhdfs) |
| [websocket](/reference/plugins-outputs-websocket.md) | Publishes messages to a websocket | [logstash-output-websocket](https://github.com/logstash-plugins/logstash-output-websocket) |
| [workplace_search (deprecated)](/reference/plugins-outputs-elastic_workplace_search.md) | [deprecated at {{stack}} version 9.0.0 and plugin version 3.0.1]  Sends events to Elastic Workplace Search | [logstash-integration-elastic_enterprise_search](https://github.com/logstash-plugins/logstash-output-elastic_app_search) |
| [xmpp](/reference/plugins-outputs-xmpp.md) | Posts events over XMPP | [logstash-output-xmpp](https://github.com/logstash-plugins/logstash-output-xmpp) |
| [zabbix](/reference/plugins-outputs-zabbix.md) | Sends events to a Zabbix server | [logstash-output-zabbix](https://github.com/logstash-plugins/logstash-output-zabbix) |



























































