# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/agent"
require "monitoring/internal_pipeline_source"
require 'helpers/elasticsearch_options'

module LogStash
  class MonitoringExtension < LogStash::UniversalPlugin
    include LogStash::Util::Loggable

    java_import java.util.concurrent.TimeUnit

    class TemplateData
      def initialize(node_uuid,
                     system_api_version,
                     es_settings,
                     collection_interval,
                     collection_timeout_interval,
                     extended_performance_collection,
                     config_collection)
        @system_api_version = system_api_version
        @node_uuid = node_uuid
        @collection_interval = collection_interval
        @collection_timeout_interval = collection_timeout_interval
        @extended_performance_collection = extended_performance_collection
        @config_collection = config_collection
        @es_hosts = es_settings['hosts']
        @user = es_settings['user']
        @password = es_settings['password']
        @cloud_id = es_settings['cloud_id']
        @cloud_auth = es_settings['cloud_auth']
        @api_key = es_settings['api_key']
        @proxy = es_settings['proxy']
        @ssl_enabled = es_settings['ssl_enabled']
        @ssl_certificate_authorities = es_settings['ssl_certificate_authorities']
        @ca_trusted_fingerprint = es_settings['ca_trusted_fingerprint']
        @ssl_truststore_path = es_settings['ssl_truststore_path']
        @ssl_truststore_password = es_settings['ssl_truststore_password']
        @ssl_keystore_path = es_settings['ssl_keystore_path']
        @ssl_keystore_password = es_settings['ssl_keystore_password']
        @ssl_verification_mode = es_settings.fetch('ssl_verification_mode', 'full')
        @ssl_certificate = es_settings['ssl_certificate']
        @ssl_key = es_settings['ssl_key']
        @ssl_cipher_suites = es_settings['ssl_cipher_suites']
        @sniffing = es_settings['sniffing']
      end

      attr_accessor :system_api_version, :es_hosts, :user, :password, :node_uuid, :cloud_id, :cloud_auth, :api_key
      attr_accessor :proxy, :ssl_enabled, :ssl_certificate_authorities, :ca_trusted_fingerprint, :ssl_truststore_path, :ssl_truststore_password
      attr_accessor :ssl_keystore_path, :ssl_keystore_password, :sniffing, :ssl_verification_mode, :ssl_cipher_suites, :ssl_certificate, :ssl_key

      def collection_interval
        TimeUnit::SECONDS.convert(@collection_interval, TimeUnit::NANOSECONDS)
      end

      def collection_timeout_interval
        TimeUnit::SECONDS.convert(@collection_timeout_interval, TimeUnit::NANOSECONDS)
      end

      def cloud_id?
        !!cloud_id
      end

      def cloud_auth?
        !!cloud_auth && cloud_id?
      end

      def proxy?
        proxy
      end

      def auth?
        user && password
      end

      def api_key?
        api_key
      end

      def ssl_enabled?
        ssl_enabled || ssl_certificate_authorities || ca_trusted_fingerprint || ssl_truststore_path? || ssl_keystore_path? || ssl_certificate?
      end

      def ssl_truststore_path?
        ssl_truststore_path && ssl_truststore_password
      end

      def ssl_keystore_path?
        ssl_keystore_path && ssl_keystore_password
      end

      def ssl_certificate?
        ssl_certificate && ssl_key
      end

      def extended_performance_collection?
        @extended_performance_collection
      end

      def config_collection?
        @config_collection
      end

      def get_binding
        binding
      end

      def monitoring_endpoint
        if LogStash::MonitoringExtension.use_direct_shipping?(LogStash::SETTINGS)
          "/_bulk/"
        else
          "/_monitoring/bulk?system_id=logstash&system_api_version=#{system_api_version}&interval=1s"
        end
      end

      def monitoring_index
        if LogStash::MonitoringExtension.use_direct_shipping?(LogStash::SETTINGS)
          ".monitoring-logstash-#{system_api_version}-" + Time.now.utc.to_date.strftime("%Y.%m.%d")
        else
          "" #let the ES xpack's reporter to create it
        end
      end
    end

    class PipelineRegisterHook
      include LogStash::Util::Loggable, LogStash::Helpers::ElasticsearchOptions

      PIPELINE_ID = ".monitoring-logstash"
      API_VERSION = 7

      def initialize
        # nothing to do here
      end

      def after_agent(runner)
        return unless monitoring_enabled?(runner.settings)

        deprecation_logger.deprecated(
            "Internal collectors option for Logstash monitoring is deprecated and targeted for removal in the next major version.\n"\
            "Please configure Elastic Agent to monitor Logstash. Documentation can be found at: \n"\
            "https://www.elastic.co/guide/en/logstash/current/monitoring-with-elastic-agent.html"
            )

        logger.trace("registering the metrics pipeline")
        LogStash::SETTINGS.set("node.uuid", runner.agent.id)
        internal_pipeline_source = LogStash::Monitoring::InternalPipelineSource.new(setup_metrics_pipeline, runner.agent, LogStash::SETTINGS.clone)
        runner.source_loader.add_source(internal_pipeline_source)
      rescue => e
        logger.error("Failed to set up the metrics pipeline", :message => e.message, :backtrace => e.backtrace)
        raise e
      end

      # For versions prior to 6.3 the default value of "xpack.monitoring.enabled" was true
      # For versions 6.3+ the default of "xpack.monitoring.enabled" is false.
      # To help keep passivity, assume that if "xpack.monitoring.elasticsearch.hosts" has been set that monitoring should be enabled.
      # return true if xpack.monitoring.enabled=true (explicitly) or xpack.monitoring.elasticsearch.hosts is configured
      def monitoring_enabled?(settings)
        return settings.get_value("monitoring.enabled") if settings.set?("monitoring.enabled")
        return settings.get_value("xpack.monitoring.enabled") if settings.set?("xpack.monitoring.enabled")

        if settings.set?("xpack.monitoring.elasticsearch.hosts") || settings.set?("xpack.monitoring.elasticsearch.cloud_id")
          logger.warn("xpack.monitoring.enabled has not been defined, but found elasticsearch configuration. Please explicitly set `xpack.monitoring.enabled: true` in logstash.yml")
          true
        else
          default = settings.get_default("xpack.monitoring.enabled")
          logger.trace("xpack.monitoring.enabled has not been defined, defaulting to default value: " + default.to_s)
          default # false as of 6.3
        end
      end

      def setup_metrics_pipeline
        settings = LogStash::SETTINGS.clone

        # reset settings for the metrics pipeline
        settings.get_setting("path.config").reset
        settings.set("pipeline.id", PIPELINE_ID)
        settings.set("config.reload.automatic", false)
        settings.set("metric.collect", false)
        settings.set("queue.type", "memory")
        settings.set("pipeline.workers", 1) # this is a low throughput pipeline
        settings.set("pipeline.batch.size", 2)
        settings.set("pipeline.system", true)

        config = generate_pipeline_config(settings)
        logger.debug("compiled metrics pipeline config: ", :config => config)

        config_part = org.logstash.common.SourceWithMetadata.new("x-pack-metrics", "internal_pipeline_source", config)
        Java::OrgLogstashConfigIr::PipelineConfig.new(self.class, PIPELINE_ID.to_sym, [config_part], settings)
      end

      def generate_pipeline_config(settings)
        if settings.set?("xpack.monitoring.enabled") && settings.set?("monitoring.enabled")
          raise ArgumentError.new("\"xpack.monitoring.enabled\" is configured while also \"monitoring.enabled\"")
        end

        if any_set?(settings, /^xpack.monitoring/) && any_set?(settings, /^monitoring./)
          raise ArgumentError.new("\"xpack.monitoring.*\" settings can't be configured while using \"monitoring.*\"")
        end

        if MonitoringExtension.use_direct_shipping?(settings)
          opt = retrieve_collection_settings(settings)
        else
          opt = retrieve_collection_settings(settings, "xpack.")
        end
        es_settings = es_options_from_settings_or_modules('monitoring', settings)
        data = TemplateData.new(LogStash::SETTINGS.get("node.uuid"), API_VERSION,
                                es_settings,
                                opt[:collection_interval], opt[:collection_timeout_interval],
                                opt[:extended_performance_collection], opt[:config_collection])

        template_path = ::File.join(::File.dirname(__FILE__), "..", "template.cfg.erb")
        template = ::File.read(template_path)
        ERB.new(template).result(data.get_binding)
      end

      private
      def retrieve_collection_settings(settings, prefix = "")
        opt = {}
        opt[:collection_interval] = settings.get("#{prefix}monitoring.collection.interval").to_nanos
        opt[:collection_timeout_interval] = settings.get("#{prefix}monitoring.collection.timeout_interval").to_nanos
        opt[:extended_performance_collection] = settings.get("#{prefix}monitoring.collection.pipeline.details.enabled")
        opt[:config_collection] = settings.get("#{prefix}monitoring.collection.config.enabled")
        opt
      end

      def any_set?(settings, regexp)
        !settings.get_subset(regexp).to_hash.keys.select { |k| settings.set?(k)}.empty?
      end
    end

    def self.use_direct_shipping?(settings)
      settings.get("monitoring.enabled")
    end

    public
    def initialize
      # nothing to do here
    end

    def register_hooks(hooks)
      logger.trace("registering hook")
      hooks.register_hooks(LogStash::Runner, PipelineRegisterHook.new)
    end

    def additionals_settings(settings)
      logger.trace("registering additionals_settings")
      register_monitoring_settings(settings, "xpack.")
      # (Experimental) Direct shipping settings
      register_monitoring_settings(settings)

      settings.register(LogStash::Setting::String.new("node.uuid", ""))
    rescue => e
      logger.error e.message
      logger.error e.backtrace.to_s
      raise e
    end

    private
    def register_monitoring_settings(settings, prefix = "")
      settings.register(LogStash::Setting::Boolean.new("#{prefix}monitoring.enabled", false))
      settings.register(LogStash::Setting::ArrayCoercible.new("#{prefix}monitoring.elasticsearch.hosts", String, ["http://localhost:9200"]))
      settings.register(LogStash::Setting::TimeValue.new("#{prefix}monitoring.collection.interval", "10s"))
      settings.register(LogStash::Setting::TimeValue.new("#{prefix}monitoring.collection.timeout_interval", "10m"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.username", "logstash_system"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.password"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.proxy"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.cloud_id"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.cloud_auth"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.api_key"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.certificate_authority"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.ca_trusted_fingerprint"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.truststore.path"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.truststore.password"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.keystore.path"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.keystore.password"))
      settings.register(LogStash::Setting::String.new("#{prefix}monitoring.elasticsearch.ssl.verification_mode", "full", true, ["none", "certificate", "full"]))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.certificate"))
      settings.register(LogStash::Setting::NullableString.new("#{prefix}monitoring.elasticsearch.ssl.key"))
      settings.register(LogStash::Setting::ArrayCoercible.new("#{prefix}monitoring.elasticsearch.ssl.cipher_suites", String, []))
      settings.register(LogStash::Setting::Boolean.new("#{prefix}monitoring.elasticsearch.sniffing", false))
      settings.register(LogStash::Setting::Boolean.new("#{prefix}monitoring.collection.pipeline.details.enabled", true))
      settings.register(LogStash::Setting::Boolean.new("#{prefix}monitoring.collection.config.enabled", true))
    end
  end
end
