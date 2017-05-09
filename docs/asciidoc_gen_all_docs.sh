#!/bin/sh

mkdir -p asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/collectd.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/elasticsearch.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/eventlog.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/exec.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/file.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/ganglia.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/gelf.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/generator.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/graphite.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/imap.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/irc.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/log4j.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/lumberjack.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/pipe.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/rabbitmq.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/redis.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/s3.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/snmptrap.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/sqs.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/stdin.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/syslog.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/tcp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/threadable.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/twitter.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/udp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/unix.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/xmpp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/inputs/zeromq.rb -o docs/asciidoc/generated

ruby docs/asciidocgen.rb lib/logstash/filters/anonymize.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/checksum.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/clone.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/csv.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/date.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/dns.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/drop.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/fingerprint.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/geoip.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/grok.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/grokdiscovery.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/json.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/kv.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/metrics.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/multiline.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/mutate.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/noop.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/ruby.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/sleep.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/split.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/spool.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/syslog_pri.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/throttle.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/urldecode.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/useragent.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/uuid.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/filters/xml.rb -o docs/asciidoc/generated

ruby docs/asciidocgen.rb lib/logstash/codecs/collectd.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/dots.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/edn.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/edn_lines.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/fluent.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/graphite.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/json.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/json_lines.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/json_spooler.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/line.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/msgpack.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/multiline.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/netflow.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/noop.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/oldlogstashjson.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/plain.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/rubydebug.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/codecs/spool.rb -o docs/asciidoc/generated

ruby docs/asciidocgen.rb lib/logstash/outputs/cloudwatch.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/csv.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/elasticsearch.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/elasticsearch_http.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/elasticsearch_river.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/email.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/exec.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/file.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/ganglia.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/gelf.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/graphite.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/hipchat.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/http.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/irc.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/juggernaut.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/lumberjack.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/nagios.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/nagios_nsca.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/null.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/opentsdb.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/pagerduty.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/pipe.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/rabbitmq.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/redis.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/s3.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/sns.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/sqs.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/statsd.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/stdout.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/tcp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/udp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/xmpp.rb -o docs/asciidoc/generated
ruby docs/asciidocgen.rb lib/logstash/outputs/zeromq.rb -o docs/asciidoc/generated

ruby docs/asciidoc_index.rb docs/asciidoc/generated inputs
ruby docs/asciidoc_index.rb docs/asciidoc/generated filters
ruby docs/asciidoc_index.rb docs/asciidoc/generated codecs
ruby docs/asciidoc_index.rb docs/asciidoc/generated outputs

