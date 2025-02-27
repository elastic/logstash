---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/filter-plugins.html
---

# Filter plugins [filter-plugins]

A filter plugin performs intermediary processing on an event. Filters are often applied conditionally depending on the characteristics of the event.

The following filter plugins are available below. For a list of Elastic supported plugins, please consult the [Support Matrix](https://www.elastic.co/support/matrix#show_logstash_plugins).

|     |     |     |
| --- | --- | --- |
| Plugin | Description | Github repository |
| [age](/reference/plugins-filters-age.md) | Calculates the age of an event by subtracting the event timestamp from the current timestamp | [logstash-filter-age](https://github.com/logstash-plugins/logstash-filter-age) |
| [aggregate](/reference/plugins-filters-aggregate.md) | Aggregates information from several events originating with a single task | [logstash-filter-aggregate](https://github.com/logstash-plugins/logstash-filter-aggregate) |
| [alter](/reference/plugins-filters-alter.md) | Performs general alterations to fields that the `mutate` filter does not handle | [logstash-filter-alter](https://github.com/logstash-plugins/logstash-filter-alter) |
| [bytes](/reference/plugins-filters-bytes.md) | Parses string representations of computer storage sizes, such as "123 MB" or "5.6gb", into their numeric value in bytes | [logstash-filter-bytes](https://github.com/logstash-plugins/logstash-filter-bytes) |
| [cidr](/reference/plugins-filters-cidr.md) | Checks IP addresses against a list of network blocks | [logstash-filter-cidr](https://github.com/logstash-plugins/logstash-filter-cidr) |
| [cipher](/reference/plugins-filters-cipher.md) | Applies or removes a cipher to an event | [logstash-filter-cipher](https://github.com/logstash-plugins/logstash-filter-cipher) |
| [clone](/reference/plugins-filters-clone.md) | Duplicates events | [logstash-filter-clone](https://github.com/logstash-plugins/logstash-filter-clone) |
| [csv](/reference/plugins-filters-csv.md) | Parses comma-separated value data into individual fields | [logstash-filter-csv](https://github.com/logstash-plugins/logstash-filter-csv) |
| [date](/reference/plugins-filters-date.md) | Parses dates from fields to use as the Logstash timestamp for an event | [logstash-filter-date](https://github.com/logstash-plugins/logstash-filter-date) |
| [de_dot](/reference/plugins-filters-de_dot.md) | Computationally expensive filter that removes dots from a field name | [logstash-filter-de_dot](https://github.com/logstash-plugins/logstash-filter-de_dot) |
| [dissect](/reference/plugins-filters-dissect.md) | Extracts unstructured event data into fields using delimiters | [logstash-filter-dissect](https://github.com/logstash-plugins/logstash-filter-dissect) |
| [dns](/reference/plugins-filters-dns.md) | Performs a standard or reverse DNS lookup | [logstash-filter-dns](https://github.com/logstash-plugins/logstash-filter-dns) |
| [drop](/reference/plugins-filters-drop.md) | Drops all events | [logstash-filter-drop](https://github.com/logstash-plugins/logstash-filter-drop) |
| [elapsed](/reference/plugins-filters-elapsed.md) | Calculates the elapsed time between a pair of events | [logstash-filter-elapsed](https://github.com/logstash-plugins/logstash-filter-elapsed) |
| [elastic_integration](/reference/plugins-filters-elastic_integration.md) | Provides additional {{ls}} processing on data from Elastic integrations | [logstash-filter-elastic_integration](https://github.com/elastic/logstash-filter-elastic_integration) |
| [elasticsearch](/reference/plugins-filters-elasticsearch.md) | Copies fields from previous log events in Elasticsearch to current events | [logstash-filter-elasticsearch](https://github.com/logstash-plugins/logstash-filter-elasticsearch) |
| [environment](/reference/plugins-filters-environment.md) | Stores environment variables as metadata sub-fields | [logstash-filter-environment](https://github.com/logstash-plugins/logstash-filter-environment) |
| [extractnumbers](/reference/plugins-filters-extractnumbers.md) | Extracts numbers from a string | [logstash-filter-extractnumbers](https://github.com/logstash-plugins/logstash-filter-extractnumbers) |
| [fingerprint](/reference/plugins-filters-fingerprint.md) | Fingerprints fields by replacing values with a consistent hash | [logstash-filter-fingerprint](https://github.com/logstash-plugins/logstash-filter-fingerprint) |
| [geoip](/reference/plugins-filters-geoip.md) | Adds geographical information about an IP address | [logstash-filter-geoip](https://github.com/logstash-plugins/logstash-filter-geoip) |
| [grok](/reference/plugins-filters-grok.md) | Parses unstructured event data into fields | [logstash-filter-grok](https://github.com/logstash-plugins/logstash-filter-grok) |
| [http](/reference/plugins-filters-http.md) | Provides integration with external web services/REST APIs | [logstash-filter-http](https://github.com/logstash-plugins/logstash-filter-http) |
| [i18n](/reference/plugins-filters-i18n.md) | Removes special characters from a field | [logstash-filter-i18n](https://github.com/logstash-plugins/logstash-filter-i18n) |
| [java_uuid](/reference/plugins-filters-java_uuid.md) | Generates a UUID and adds it to each processed event | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/filters/Uuid.java) |
| [jdbc_static](/reference/plugins-filters-jdbc_static.md) | Enriches events with data pre-loaded from a remote database | [logstash-integration-jdbc](https://github.com/logstash-plugins/logstash-integration-jdbc) |
| [jdbc_streaming](/reference/plugins-filters-jdbc_streaming.md) | Enrich events with your database data | [logstash-integration-jdbc](https://github.com/logstash-plugins/logstash-integration-jdbc) |
| [json](/reference/plugins-filters-json.md) | Parses JSON events | [logstash-filter-json](https://github.com/logstash-plugins/logstash-filter-json) |
| [json_encode](/reference/plugins-filters-json_encode.md) | Serializes a field to JSON | [logstash-filter-json_encode](https://github.com/logstash-plugins/logstash-filter-json_encode) |
| [kv](/reference/plugins-filters-kv.md) | Parses key-value pairs | [logstash-filter-kv](https://github.com/logstash-plugins/logstash-filter-kv) |
| [memcached](/reference/plugins-filters-memcached.md) | Provides integration with external data in Memcached | [logstash-filter-memcached](https://github.com/logstash-plugins/logstash-filter-memcached) |
| [metricize](/reference/plugins-filters-metricize.md) | Takes complex events containing a number of metrics and splits these up into multiple events, each holding a single metric | [logstash-filter-metricize](https://github.com/logstash-plugins/logstash-filter-metricize) |
| [metrics](/reference/plugins-filters-metrics.md) | Aggregates metrics | [logstash-filter-metrics](https://github.com/logstash-plugins/logstash-filter-metrics) |
| [mutate](/reference/plugins-filters-mutate.md) | Performs mutations on fields | [logstash-filter-mutate](https://github.com/logstash-plugins/logstash-filter-mutate) |
| [prune](/reference/plugins-filters-prune.md) | Prunes event data based on a list of fields to blacklist or whitelist | [logstash-filter-prune](https://github.com/logstash-plugins/logstash-filter-prune) |
| [range](/reference/plugins-filters-range.md) | Checks that specified fields stay within given size or length limits | [logstash-filter-range](https://github.com/logstash-plugins/logstash-filter-range) |
| [ruby](/reference/plugins-filters-ruby.md) | Executes arbitrary Ruby code | [logstash-filter-ruby](https://github.com/logstash-plugins/logstash-filter-ruby) |
| [sleep](/reference/plugins-filters-sleep.md) | Sleeps for a specified time span | [logstash-filter-sleep](https://github.com/logstash-plugins/logstash-filter-sleep) |
| [split](/reference/plugins-filters-split.md) | Splits multi-line messages, strings, or arrays into distinct events | [logstash-filter-split](https://github.com/logstash-plugins/logstash-filter-split) |
| [syslog_pri](/reference/plugins-filters-syslog_pri.md) | Parses the `PRI` (priority) field of a `syslog` message | [logstash-filter-syslog_pri](https://github.com/logstash-plugins/logstash-filter-syslog_pri) |
| [threats_classifier](/reference/plugins-filters-threats_classifier.md) | Enriches security logs with information about the attacker’s intent | [logstash-filter-threats_classifier](https://github.com/empow/logstash-filter-threats_classifier) |
| [throttle](/reference/plugins-filters-throttle.md) | Throttles the number of events | [logstash-filter-throttle](https://github.com/logstash-plugins/logstash-filter-throttle) |
| [tld](/reference/plugins-filters-tld.md) | Replaces the contents of the default message field with whatever you specify in the configuration | [logstash-filter-tld](https://github.com/logstash-plugins/logstash-filter-tld) |
| [translate](/reference/plugins-filters-translate.md) | Replaces field contents based on a hash or YAML file | [logstash-filter-translate](https://github.com/logstash-plugins/logstash-filter-translate) |
| [truncate](/reference/plugins-filters-truncate.md) | Truncates fields longer than a given length | [logstash-filter-truncate](https://github.com/logstash-plugins/logstash-filter-truncate) |
| [urldecode](/reference/plugins-filters-urldecode.md) | Decodes URL-encoded fields | [logstash-filter-urldecode](https://github.com/logstash-plugins/logstash-filter-urldecode) |
| [useragent](/reference/plugins-filters-useragent.md) | Parses user agent strings into fields | [logstash-filter-useragent](https://github.com/logstash-plugins/logstash-filter-useragent) |
| [uuid](/reference/plugins-filters-uuid.md) | Adds a UUID to events | [logstash-filter-uuid](https://github.com/logstash-plugins/logstash-filter-uuid) |
| [wurfl_device_detection](/reference/plugins-filters-wurfl_device_detection.md) | Enriches logs with device information such as brand, model, OS | [logstash-filter-wurfl_device_detection](https://github.com/WURFL/logstash-filter-wurfl_device_detection) |
| [xml](/reference/plugins-filters-xml.md) | Parses XML into fields | [logstash-filter-xml](https://github.com/logstash-plugins/logstash-filter-xml) |


















































