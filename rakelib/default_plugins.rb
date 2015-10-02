module LogStash
  module RakeLib

    # plugins included by default in the logstash distribution
    DEFAULT_PLUGINS = %w(
      logstash-input-heartbeat
      logstash-output-zeromq
      logstash-codec-collectd
      logstash-output-xmpp
      logstash-codec-dots
      logstash-codec-edn
      logstash-codec-edn_lines
      logstash-codec-fluent
      logstash-codec-es_bulk
      logstash-codec-graphite
      logstash-codec-json
      logstash-codec-json_lines
      logstash-codec-line
      logstash-codec-msgpack
      logstash-codec-multiline
      logstash-codec-netflow
      logstash-codec-oldlogstashjson
      logstash-codec-plain
      logstash-codec-rubydebug
      logstash-filter-anonymize
      logstash-filter-checksum
      logstash-filter-clone
      logstash-filter-csv
      logstash-filter-date
      logstash-filter-dns
      logstash-filter-drop
      logstash-filter-fingerprint
      logstash-filter-geoip
      logstash-filter-grok
      logstash-filter-json
      logstash-filter-kv
      logstash-filter-metrics
      logstash-filter-multiline
      logstash-filter-mutate
      logstash-filter-ruby
      logstash-filter-sleep
      logstash-filter-split
      logstash-filter-syslog_pri
      logstash-filter-throttle
      logstash-filter-urldecode
      logstash-filter-useragent
      logstash-filter-uuid
      logstash-filter-xml
      logstash-input-couchdb_changes
      logstash-input-elasticsearch
      logstash-input-eventlog
      logstash-input-exec
      logstash-input-file
      logstash-input-ganglia
      logstash-input-gelf
      logstash-input-generator
      logstash-input-graphite
      logstash-input-http
      logstash-input-imap
      logstash-input-irc
      logstash-input-log4j
      logstash-input-lumberjack
      logstash-input-pipe
      logstash-input-rabbitmq
      logstash-input-redis
      logstash-input-s3
      logstash-input-snmptrap
      logstash-input-sqs
      logstash-input-stdin
      logstash-input-syslog
      logstash-input-tcp
      logstash-input-twitter
      logstash-input-udp
      logstash-input-unix
      logstash-input-xmpp
      logstash-input-zeromq
      logstash-input-kafka
      logstash-output-cloudwatch
      logstash-output-csv
      logstash-output-elasticsearch
      logstash-output-email
      logstash-output-exec
      logstash-output-file
      logstash-output-ganglia
      logstash-output-gelf
      logstash-output-graphite
      logstash-output-hipchat
      logstash-output-http
      logstash-output-irc
      logstash-output-juggernaut
      logstash-output-lumberjack
      logstash-output-nagios
      logstash-output-nagios_nsca
      logstash-output-null
      logstash-output-opentsdb
      logstash-output-pagerduty
      logstash-output-pipe
      logstash-output-rabbitmq
      logstash-output-redis
      logstash-output-s3
      logstash-output-sns
      logstash-output-sqs
      logstash-output-statsd
      logstash-output-stdout
      logstash-output-tcp
      logstash-output-udp
      logstash-output-kafka
    )

    # plugins required to run the logstash core specs
    CORE_SPECS_PLUGINS = %w(
      logstash-filter-clone
      logstash-filter-mutate
      logstash-filter-multiline
      logstash-input-generator
      logstash-input-stdin
      logstash-input-tcp
      logstash-output-stdout
    )

    TEST_JAR_DEPENDENCIES_PLUGINS = %w(
      logstash-input-kafka
    )

    TEST_VENDOR_PLUGINS = %w(
      logstash-codec-collectd
    )

    ALL_PLUGINS_SKIP_LIST = Regexp.union([
      /^logstash-filter-yaml$/,
      /jms$/,
      /example$/,
      /drupal/i,
      /^logstash-output-logentries$/,
      /^logstash-input-jdbc$/,
      /^logstash-output-newrelic$/,
      /^logstash-output-slack$/,
      /^logstash-input-neo4j$/,
      /^logstash-output-neo4j$/,
      /^logstash-input-perfmon$/,
      /^logstash-output-webhdfs$/,
      /^logstash-input-rackspace$/,
      /^logstash-output-rackspace$/,
      /^logstash-input-dynamodb$/
    ])


    # @return [Array<String>] list of all plugin names as defined in the logstash-plugins github organization, minus names that matches the ALL_PLUGINS_SKIP_LIST
    def self.fetch_all_plugins
      require 'octokit'
      Octokit.auto_paginate = true
      repos = Octokit.organization_repositories("logstash-plugins")
      repos.map(&:name).reject do |name|
        name =~ ALL_PLUGINS_SKIP_LIST || !is_released?(name)
      end
    end

    def self.is_released?(plugin)
      require 'gems'
      Gems.info(plugin) != "This rubygem could not be found."
    end
  end
end
