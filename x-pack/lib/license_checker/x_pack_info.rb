# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/json"
require 'license_checker/license_reader'
java_import java.util.concurrent.Executors
java_import java.util.concurrent.TimeUnit

module LogStash
  module LicenseChecker
    LICENSE_TYPES = ['trial', 'basic', 'standard', 'gold', 'platinum', 'enterprise']

    class XPackInfo
      include LogStash::Util::Loggable

      def initialize(license, features = nil, installed = true, failed = false)
        @license = license
        @installed = installed
        @features = features
        @failed = failed

        freeze
      end

      def method_missing(meth)
        if meth.to_s.match(/license_(.+)/)
          return nil if @license.nil?
          @license[$1]
        else
          super
        end
      end

      def failed?
        @failed
      end

      def installed?
        @installed
      end

      def license_available?
        !@license.nil?
      end

      def license_active?
        return false if @license.nil?
        license_status == 'active'
      end

      def license_one_of?(types)
        return false if @license.nil?
        types.include?(license_type)
      end

      def feature_enabled?(feature)
        return false if @features.nil?
        return false unless @features.include?(feature)
        return false unless @features[feature].fetch('available', false)

        @features[feature].fetch('enabled', false)
      end

      def to_s
         "installed:#{installed?},
          license:#{@license.nil? ? '<no license loaded>' : @license.to_s},
          features:#{@features.nil? ? '<no features loaded>' : @features.to_s},
          last_updated:#{@last_updated}}"
      end

      def ==(other)
        return false if other.nil?

        return false unless other.instance_variable_get(:@installed) == @installed
        return false unless other.instance_variable_get(:@license) == @license
        return false unless other.instance_variable_get(:@features) == @features

        true
      end

      def self.from_es_response(es_response)
        if es_response.nil? || es_response['license'].nil?
          logger.warn("Nil response from License Server")
          XPackInfo.new(nil)
        else
          license = es_response.fetch('license', {}).dup.freeze
          features = es_response.fetch('features', {}).dup.freeze

          XPackInfo.new(license, features)
        end
      end

      def self.xpack_not_installed
        XPackInfo.new(nil, nil, false)
      end

      def self.failed_to_fetch
        XPackInfo.new(nil, nil, false, true)
      end

      def self.serverless_response
        SERVERLESS_20231031
      end

      # "Elastic-Api-Version": "2023-10-31" is the first API version available in serverless
      SERVERLESS_20231031 = XPackInfo.from_es_response(
        {
          "license" =>
            {
              "type" => "enterprise",
              "mode" => "enterprise",
              "status" => "active"
            },
          "features" =>
            {
              "aggregate_metric" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "analytics" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "archive" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "ccr" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "cluster =>monitor/xpack/info/ilm" =>
                {
                  "available" => false,
                  "enabled" => false
                },
              "cluster =>monitor/xpack/info/monitoring" =>
                {
                  "available" => false,
                  "enabled" => false
                },
              "cluster =>monitor/xpack/info/searchable_snapshots" =>
                {
                  "available" => false,
                  "enabled" => false
                },
              "cluster =>monitor/xpack/info/voting_only" =>
                {
                  "available" => false,
                  "enabled" => false
                },
              "cluster =>monitor/xpack/info/watcher" =>
                {
                  "available" => false,
                  "enabled" => false
                },
              "data_streams" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "data_tiers" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "enrich" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "enterprise_search" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "eql" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "frozen_indices" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "graph" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "logstash" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "ml" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "rollup" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "security" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "slm" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "spatial" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "sql" =>
                {
                  "available" => true,
                  "enabled" => true
                },
              "transform" =>
                {
                  "available" => true,
                  "enabled" => true
                }
            }
        }
      ).freeze
    end
  end
end
