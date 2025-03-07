---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/codec-plugins.html
---

# Codec plugins [codec-plugins]

A codec plugin changes the data representation of an event. Codecs are essentially stream filters that can operate as part of an input or output.

The following codec plugins are available below. For a list of Elastic supported plugins, please consult the [Support Matrix](https://www.elastic.co/support/matrix#show_logstash_plugins).

|     |     |     |
| --- | --- | --- |
| Plugin | Description | Github repository |
| [avro](/reference/plugins-codecs-avro.md) | Reads serialized Avro records as Logstash events | [logstash-codec-avro](https://github.com/logstash-plugins/logstash-codec-avro) |
| [cef](/reference/plugins-codecs-cef.md) | Reads the ArcSight Common Event Format (CEF). | [logstash-codec-cef](https://github.com/logstash-plugins/logstash-codec-cef) |
| [cloudfront](/reference/plugins-codecs-cloudfront.md) | Reads AWS CloudFront reports | [logstash-codec-cloudfront](https://github.com/logstash-plugins/logstash-codec-cloudfront) |
| [cloudtrail](/reference/plugins-codecs-cloudtrail.md) | Reads AWS CloudTrail log files | [logstash-codec-cloudtrail](https://github.com/logstash-plugins/logstash-codec-cloudtrail) |
| [collectd](/reference/plugins-codecs-collectd.md) | Reads events from the `collectd` binary protocol using UDP. | [logstash-codec-collectd](https://github.com/logstash-plugins/logstash-codec-collectd) |
| [csv](/reference/plugins-codecs-csv.md) | Takes CSV data, parses it, and passes it along. | [logstash-codec-csv](https://github.com/logstash-plugins/logstash-codec-csv) |
| [dots](/reference/plugins-codecs-dots.md) | Sends 1 dot per event to `stdout` for performance tracking | [logstash-codec-dots](https://github.com/logstash-plugins/logstash-codec-dots) |
| [edn](/reference/plugins-codecs-edn.md) | Reads EDN format data | [logstash-codec-edn](https://github.com/logstash-plugins/logstash-codec-edn) |
| [edn_lines](/reference/plugins-codecs-edn_lines.md) | Reads newline-delimited EDN format data | [logstash-codec-edn_lines](https://github.com/logstash-plugins/logstash-codec-edn_lines) |
| [es_bulk](/reference/plugins-codecs-es_bulk.md) | Reads the Elasticsearch bulk format into separate events, along with metadata | [logstash-codec-es_bulk](https://github.com/logstash-plugins/logstash-codec-es_bulk) |
| [fluent](/reference/plugins-codecs-fluent.md) | Reads the `fluentd` `msgpack` schema | [logstash-codec-fluent](https://github.com/logstash-plugins/logstash-codec-fluent) |
| [graphite](/reference/plugins-codecs-graphite.md) | Reads `graphite` formatted lines | [logstash-codec-graphite](https://github.com/logstash-plugins/logstash-codec-graphite) |
| [gzip_lines](/reference/plugins-codecs-gzip_lines.md) | Reads `gzip` encoded content | [logstash-codec-gzip_lines](https://github.com/logstash-plugins/logstash-codec-gzip_lines) |
| [jdots](/reference/plugins-codecs-jdots.md) | Renders each processed event as a dot | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/codecs/Dots.java) |
| [java_line](/reference/plugins-codecs-java_line.md) | Encodes and decodes line-oriented text data | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/codecs/Line.java) |
| [java_plain](/reference/plugins-codecs-java_plain.md) | Processes text data with no delimiters between events | [core plugin](https://github.com/elastic/logstash/blob/master/logstash-core/src/main/java/org/logstash/plugins/codecs/Plain.java) |
| [json](/reference/plugins-codecs-json.md) | Reads JSON formatted content, creating one event per element in a JSON array | [logstash-codec-json](https://github.com/logstash-plugins/logstash-codec-json) |
| [json_lines](/reference/plugins-codecs-json_lines.md) | Reads newline-delimited JSON | [logstash-codec-json_lines](https://github.com/logstash-plugins/logstash-codec-json_lines) |
| [line](/reference/plugins-codecs-line.md) | Reads line-oriented text data | [logstash-codec-line](https://github.com/logstash-plugins/logstash-codec-line) |
| [msgpack](/reference/plugins-codecs-msgpack.md) | Reads MessagePack encoded content | [logstash-codec-msgpack](https://github.com/logstash-plugins/logstash-codec-msgpack) |
| [multiline](/reference/plugins-codecs-multiline.md) | Merges multiline messages into a single event | [logstash-codec-multiline](https://github.com/logstash-plugins/logstash-codec-multiline) |
| [netflow](/reference/plugins-codecs-netflow.md) | Reads Netflow v5 and Netflow v9 data | [logstash-codec-netflow](https://github.com/logstash-plugins/logstash-codec-netflow) |
| [nmap](/reference/plugins-codecs-nmap.md) | Reads Nmap data in XML format | [logstash-codec-nmap](https://github.com/logstash-plugins/logstash-codec-nmap) |
| [plain](/reference/plugins-codecs-plain.md) | Reads plaintext with no delimiting between events | [logstash-codec-plain](https://github.com/logstash-plugins/logstash-codec-plain) |
| [protobuf](/reference/plugins-codecs-protobuf.md) | Reads protobuf messages and converts to Logstash Events | [logstash-codec-protobuf](https://github.com/logstash-plugins/logstash-codec-protobuf) |
| [rubydebug](/reference/plugins-codecs-rubydebug.md) | Applies the Ruby Awesome Print library to Logstash events | [logstash-codec-rubydebug](https://github.com/logstash-plugins/logstash-codec-rubydebug) |



























