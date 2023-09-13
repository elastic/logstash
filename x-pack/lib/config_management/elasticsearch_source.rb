# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/config/source/base"
require "logstash/config/source_loader"
require "logstash/outputs/elasticsearch"
require "logstash/json"
require 'helpers/elasticsearch_options'
require 'helpers/loggable_try'
require "license_checker/licensed"

module LogStash
  module ConfigManagement
    class ElasticsearchSource < LogStash::Config::Source::Base
      include LogStash::Util::Loggable, LogStash::LicenseChecker::Licensed,
              LogStash::Helpers::ElasticsearchOptions

      class RemoteConfigError < LogStash::Error; end

      # exclude basic
      VALID_LICENSES = %w(trial standard gold platinum enterprise)
      FEATURE_INTERNAL = 'management'
      FEATURE_EXTERNAL = 'logstash'
      SUPPORTED_PIPELINE_SETTINGS = %w(
        pipeline.workers
        pipeline.batch.size
        pipeline.batch.delay
        pipeline.ecs_compatibility
        pipeline.ordered
        queue.type
        queue.max_bytes
        queue.checkpoint.writes
      )

      def initialize(settings)
        super(settings)

        if enabled?
          @es_options = es_options_from_settings('management', settings)
          setup_license_checker(FEATURE_INTERNAL)
          license_check(true)
        end
      end

      def match?
        @settings.get("xpack.management.enabled")
      end

      def config_conflict?
        false
      end

      # decide using system indices api (7.10+) or legacy api (< 7.10) base on elasticsearch server version
      def get_pipeline_fetcher(es_version)
        (es_version[:major] >= 8 || (es_version[:major] == 7 && es_version[:minor] >= 10)) ? SystemIndicesFetcher.new : LegacyHiddenIndicesFetcher.new
      end

      def pipeline_configs
        logger.trace("Fetch remote config pipeline", :pipeline_ids => pipeline_ids)

        begin
          license_check(true)
        rescue LogStash::LicenseChecker::LicenseError => e
          if @cached_pipelines.nil?
            raise e
          else
            return @cached_pipelines
          end
        end
        es_version = get_es_version
        fetcher = get_pipeline_fetcher(es_version)
        fetcher.fetch_config(es_version, pipeline_ids, client)

        @cached_pipelines = fetcher.get_pipeline_ids.collect do |pid|
          get_pipeline(pid, fetcher)
        end.compact
      end

      def get_es_version
        retry_handler = ::LogStash::Helpers::LoggableTry.new(logger, 'fetch ES version from Central Management')
        response = retry_handler.try(10.times, ::LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError) {
          client.get("/")
        }

        if response["error"]
          raise RemoteConfigError, "Cannot find elasticsearch version, server returned status: `#{response["status"]}`, message: `#{response["error"]}`"
        end

        logger.debug("Reading configuration from Elasticsearch version {}", response["version"]["number"])
        version_number = response["version"]["number"].split(".")
        { major: version_number[0].to_i, minor: version_number[1].to_i }
      end

      def get_pipeline(pipeline_id, fetcher)
        config_string = fetcher.get_single_pipeline_setting(pipeline_id)["pipeline"]
        pipeline_metadata_str = (fetcher.get_single_pipeline_setting(pipeline_id)["pipeline_metadata"] || "").to_s

        raise RemoteConfigError, "Empty configuration for pipeline_id: #{pipeline_id}" if config_string.nil? || config_string.empty?

        config_part = org.logstash.common.SourceWithMetadata.new("x-pack-config-management", pipeline_id.to_s, config_string, pipeline_metadata_str)

        # We don't support multiple pipelines, so use the global settings from the logstash.yml file
        settings = @settings.clone
        settings.set("pipeline.id", pipeline_id)

        # override global settings with pipeline settings from ES, if any
        pipeline_settings = fetcher.get_single_pipeline_setting(pipeline_id)["pipeline_settings"]
        unless pipeline_settings.nil?
          pipeline_settings.each do |setting, value|
            if SUPPORTED_PIPELINE_SETTINGS.include? setting
              settings.set(setting, value) if value
            else
              logger.warn("Ignoring unsupported or unknown pipeline settings '#{setting}'")
            end
          end
        end

        Java::OrgLogstashConfigIr::PipelineConfig.new(self.class, pipeline_id.to_sym, [config_part], settings)
      end

      # This is a bit of a hack until we refactor the ElasticSearch plugins
      # and extract correctly the http client, right now I am using the plugins
      # to deal with the certificates and the other SSL options
      #
      # But we have to silence the logger from the plugin, to make sure the
      # log originate from the `ElasticsearchSource`
      def build_client
        es = LogStash::Outputs::ElasticSearch.new(es_options_with_product_origin_header(@es_options))
        new_logger = logger
        es.instance_eval { @logger = new_logger }
        es.build_client
      end

      def populate_license_state(xpack_info, is_serverless)
        if xpack_info.failed?
          {
              :state => :error,
              :log_level => :error,
              :log_message => "Failed to fetch X-Pack information from Elasticsearch. This is likely due to failure to reach a live Elasticsearch cluster."
          }
        elsif !xpack_info.installed?
          {
              :state => :error,
              :log_level => :error,
              :log_message => "X-Pack is installed on Logstash but not on Elasticsearch. Please install X-Pack on Elasticsearch to use the monitoring feature. Other features may be available."
          }
        elsif !xpack_info.feature_enabled?("security")
          {
              :state => :error,
              :log_level => :error,
              :log_message => "X-Pack Security needs to be enabled in Elasticsearch. Please set xpack.security.enabled: true in elasticsearch.yml."
          }
        elsif !xpack_info.license_available?
          {
              :state => :error,
              :log_level => :error,
              :log_message => 'Configuration Management is not available: License information is currently unavailable. Please make sure you have added your production elasticsearch connection info in the xpack.monitoring.elasticsearch settings.'
          }
        elsif !xpack_info.license_one_of?(VALID_LICENSES)
          {
              :state => :error,
              :log_level => :error,
              :log_message => "Configuration Management is not available: #{xpack_info.license_type} is not a valid license for this feature."
          }
        elsif !xpack_info.license_active?
          {
              :state => :ok,
              :log_level => :warn,
              :log_message => 'Configuration Management feature requires a valid license. You can continue to monitor Logstash, but please contact your administrator to update your license'
          }
        else
          unless xpack_info.feature_enabled?(FEATURE_EXTERNAL)
            logger.warn('Central Pipeline Management is enabled in Logstash, but not enabled in Elasticsearch')
          end

          { :state => :ok, :log_level => :info, :log_message => 'Configuration Management License OK' }
        end
      end

      alias_method :enabled?, :match?

      private
      def pipeline_ids
        @settings.get("xpack.management.pipeline.id")
      end

      def client
        @client ||= build_client
      end
    end

    module Fetcher
      include LogStash::Util::Loggable

      def get_pipeline_ids
        @pipelines.keys
      end

      def fetch_config(es_version, pipeline_ids, client) end
      def get_single_pipeline_setting(pipeline_id) end

      def log_pipeline_not_found(pipeline_ids)
        logger.debug("Could not find a remote configuration for specific `pipeline_id`", :pipeline_ids => pipeline_ids) if pipeline_ids.any?
      end
    end

    class SystemIndicesFetcher
      include LogStash::Util::Loggable, Fetcher

      SYSTEM_INDICES_API_PATH = "_logstash/pipeline"

      def fetch_config(es_version, pipeline_ids, client)
        es_supports_pipeline_wildcard_search = es_supports_pipeline_wildcard_search?(es_version)
        retry_handler = ::LogStash::Helpers::LoggableTry.new(logger, 'fetch pipelines from Central Management')
        response = retry_handler.try(10.times, ::LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError) {
          path = es_supports_pipeline_wildcard_search ?
                   "#{SYSTEM_INDICES_API_PATH}?id=#{ERB::Util.url_encode(pipeline_ids.join(","))}" :
                   "#{SYSTEM_INDICES_API_PATH}/"
          client.get(path)
        }

        if response["error"]
          raise ElasticsearchSource::RemoteConfigError, "Cannot find find configuration for pipeline_id: #{pipeline_ids}, server returned status: `#{response["status"]}`, message: `#{response["error"]}`"
        end

        @pipelines = es_supports_pipeline_wildcard_search ?
                       response :
                       get_wildcard_pipelines(pipeline_ids, response)
      end

      def es_supports_pipeline_wildcard_search?(es_version)
        (es_version[:major] > 8) || (es_version[:major] == 8 && es_version[:minor] >= 3)
      end

      def get_single_pipeline_setting(pipeline_id)
        @pipelines.fetch(pipeline_id, {})
      end

      private
      # get pipelines if pipeline_ids match wildcard patterns
      # split user pipeline id setting into wildcard and non wildcard pattern
      # take the non wildcard pipelines. take the wildcard pipelines by matching with glob pattern
      def get_wildcard_pipelines(pipeline_ids, response)
        wildcard_patterns, fix_pids = pipeline_ids.partition { |pattern| pattern.include?("*")}

        fix_id_pipelines = fix_pids.map { |id|
          response.has_key?(id) ? {id => response[id]} : {}
        }.reduce({}, :merge)
        fix_id_pipelines.keys.map { |id| response.delete(id)}

        wildcard_matched_patterns = Set.new
        wildcard_pipelines = response.keys.map { |id|
          found_pattern = wildcard_patterns.any? { |pattern|
            matched = ::File::fnmatch?(pattern, id)
            wildcard_matched_patterns << pattern if matched
            matched
          }
          found_pattern ? {id => response[id]} : {}
        }.reduce({}, :merge)

        log_pipeline_not_found((fix_pids - fix_id_pipelines.keys) + (wildcard_patterns - wildcard_matched_patterns.to_a))

        fix_id_pipelines.merge(wildcard_pipelines)
      end
    end

    # clean up LegacyHiddenIndicesFetcher https://github.com/elastic/logstash/issues/12291
    class LegacyHiddenIndicesFetcher
      include LogStash::Util::Loggable, Fetcher

      PIPELINE_INDEX = ".logstash"

      def fetch_config(es_version, pipeline_ids, client)
        request_body_string = LogStash::Json.dump({ "docs" => pipeline_ids.collect { |pipeline_id| { "_id" => pipeline_id } } })
        retry_handler = ::LogStash::Helpers::LoggableTry.new(logger, 'fetch pipelines from Central Management')
        response = retry_handler.try(10.times, ::LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError) {
          client.post("#{PIPELINE_INDEX}/_mget", {}, request_body_string)
        }

        if response["error"]
          raise ElasticsearchSource::RemoteConfigError, "Cannot find find configuration for pipeline_id: #{pipeline_ids}, server returned status: `#{response["status"]}`, message: `#{response["error"]}`"
        end

        if response["docs"].nil?
          logger.debug("Server returned an unknown or malformed document structure", :response => response)
          raise ElasticsearchSource::RemoteConfigError, "Elasticsearch returned an unknown or malformed document structure"
        end

        @pipelines = format_response(response)

        log_wildcard_unsupported(pipeline_ids)
        log_pipeline_not_found(pipeline_ids - @pipelines.keys)

        @pipelines
      end

      def get_single_pipeline_setting(pipeline_id)
        @pipelines.fetch(pipeline_id, {}).fetch("_source", {})
      end

      private
      # transform legacy response to be similar to system indices response
      def format_response(response)
        response["docs"].map { |pipeline|
          {pipeline["_id"] => pipeline} if pipeline.fetch("found", false)
        }.compact
        .reduce({}, :merge)
      end

      def log_wildcard_unsupported(pipeline_ids)
        has_wildcard = pipeline_ids.any? { |id| id.include?("*") }
        if has_wildcard
          logger.warn("wildcard '*' in xpack.management.pipeline.id is not supported in Elasticsearch version < 7.10")
        end
      end
    end
  end
end
