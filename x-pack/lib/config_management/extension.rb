# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/environment"
require "config_management/hooks"
require "config_management/elasticsearch_source"
require "config_management/bootstrap_check"

module LogStash
  module ConfigManagement
    class Extension < LogStash::UniversalPlugin
      include LogStash::Util::Loggable

      def register_hooks(hooks)
        require "logstash/runner"
        hooks.register_hooks(LogStash::Runner, Hooks.new)
      end

      def additionals_settings(settings)
        require "logstash/runner"
        logger.trace("Registering additionals settings")

        settings.register(LogStash::Setting::Boolean.new("xpack.management.enabled", false))
        settings.register(LogStash::Setting::TimeValue.new("xpack.management.logstash.poll_interval", "5s"))
        settings.register(LogStash::Setting::ArrayCoercible.new("xpack.management.pipeline.id", String, ["main"]))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.username", "logstash_system"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.password"))
        settings.register(LogStash::Setting::ArrayCoercible.new("xpack.management.elasticsearch.hosts", String, ["https://localhost:9200"]))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.cloud_id"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.cloud_auth"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.api_key"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.proxy"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.certificate_authority"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.ca_trusted_fingerprint"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.truststore.path"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.truststore.password"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.keystore.path"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.keystore.password"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.certificate"))
        settings.register(LogStash::Setting::NullableString.new("xpack.management.elasticsearch.ssl.key"))
        settings.register(LogStash::Setting::ArrayCoercible.new("xpack.management.elasticsearch.ssl.cipher_suites", String, []))
        settings.register(LogStash::Setting::String.new("xpack.management.elasticsearch.ssl.verification_mode", "full", true, %w[none certificate full]))
        settings.register(LogStash::Setting::Boolean.new("xpack.management.elasticsearch.sniffing", false))
      rescue => e
        logger.error("Cannot register new settings", :message => e.message, :backtrace => e.backtrace)
        raise e
      end
    end
  end
end
