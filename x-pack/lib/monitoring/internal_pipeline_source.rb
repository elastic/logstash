# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/config/source/base"
require 'license_checker/licensed'
require 'helpers/elasticsearch_options'

module LogStash module Monitoring
  class InternalPipelineSource < LogStash::Config::Source::Base
    include LogStash::LicenseChecker::Licensed
    include LogStash::Helpers::ElasticsearchOptions
    include LogStash::Util::Loggable
    FEATURE = 'monitoring'

    def initialize(pipeline_config, agent, settings)
      super(pipeline_config.settings)
      @pipeline_config = pipeline_config
      @settings = settings
      @agent = agent
      @es_options = es_options_from_settings_or_modules(FEATURE, @settings)
      setup_license_checker(FEATURE)
    end

    def pipeline_configs
      @pipeline_config
    end

    def match?
      valid_basic_license?
    end

    def update_license_state(xpack_info, is_serverless)
      return if valid_basic_license?
      super(xpack_info, is_serverless) if xpack_info
      if valid_basic_license?
        logger.info("Validated license for monitoring. Enabling monitoring pipeline.")
        enable_monitoring
      end
    end

    private
    def valid_basic_license?
      @license_state ? license_check : false
    end

    def enable_monitoring
      @agent.converge_state_and_update_if_running
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
      elsif !xpack_info.license_available?
        {
            :state => :error,
            :log_level => :error,
            :log_message => 'Monitoring is not available: License information is currently unavailable. Please make sure you have added your production elasticsearch connection info in the xpack.monitoring.elasticsearch settings.'
        }
      elsif !xpack_info.license_one_of?(::LogStash::LicenseChecker::LICENSE_TYPES)
        {
            :state => :error,
            :log_level => :error,
            :log_message => "Monitoring is not available: #{xpack_info.license_type} is not a valid license for this feature."
        }
      elsif !xpack_info.feature_enabled?(FEATURE) && is_serverless
        {
          :state => :error,
          :log_level => :error,
          :log_message => "Internal collection for monitoring is enabled in Logstash, but is not supported in the configured version of Elasticsearch.\n"\
            "This instance of Logstash will NOT send its monitoring data to Elasticsearch. Please configure Elastic Agent to monitor Logstash. Documentation can be found at: \n"\
            "https://www.elastic.co/guide/en/logstash/current/monitoring-with-elastic-agent.html"
        }
      elsif !xpack_info.license_active?
        {
            :state => :ok,
            :log_level => :warn,
            :log_message => 'Monitoring requires a valid license. You can continue to monitor Logstash, but please contact your administrator to update your license'
        }
      else
        unless xpack_info.feature_enabled?(FEATURE)
          logger.warn('Monitoring installed and enabled in Logstash, but not enabled in Elasticsearch')
        end

        { :state => :ok, :log_level => :info, :log_message => 'Monitoring License OK' }
      end
    end

  end
end end
