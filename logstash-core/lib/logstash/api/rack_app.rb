# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "rack"
require "sinatra/base"
require "logstash/api/modules/base"
require "logstash/api/modules/health_report"
require "logstash/api/modules/node"
require "logstash/api/modules/node_stats"
require "logstash/api/modules/plugins"
require "logstash/api/modules/root"
require "logstash/api/modules/logging"
require "logstash/api/modules/stats"

module LogStash
  module Api
    module RackApp
      METADATA_FIELDS = [:request_method, :path_info, :query_string, :http_version, :http_accept].freeze
      def self.log_metadata(status, env)
        METADATA_FIELDS.reduce({:status => status}) do |acc, field|
          acc[field] = env[field.to_s.upcase]
          acc
        end
      end

      class ApiLogger
        LOG_MESSAGE = "API HTTP Request".freeze

        def initialize(app, logger)
          @app = app
          @logger = logger
        end

        def call(env)
          res = @app.call(env)
          status, headers, body = res

          if fatal_error?(status)
            @logger.error? && @logger.error(LOG_MESSAGE, RackApp.log_metadata(status, env))
          else
            @logger.debug? && @logger.debug(LOG_MESSAGE, RackApp.log_metadata(status, env))
          end

          res
        end

        def fatal_error?(status)
          status >= 500 && status < 600
        end
      end

      class ApiErrorHandler
        LOG_MESSAGE = "Internal API server error".freeze

        def initialize(app, logger)
          @app = app
          @logger = logger
        end

        def call(env)
          @app.call(env)
        rescue => e
          body = RackApp.log_metadata(500, env).
                   merge({
                           :error => "Unexpected Internal Error",
                           :class => e.class.name,
                           :message => e.message,
                           :backtrace => e.backtrace
                         })

          @logger.error(LOG_MESSAGE, body)

          [500,
           {'Content-Type' => 'application/json'},
           [LogStash::Json.dump(body)]
          ]
        end
      end

      def self.app(logger, agent, environment)
        # LS should avoid loading sinatra/main.rb as it does not need the full Sinatra functionality
        # such as configuration based on ARGV (actually dangerous if there's a --name collision),
        # pretty much the only piece needed is the DSL but even that only for the rackup part :
        Rack::Builder.send(:include, Sinatra::Delegator) unless Rack::Builder < Sinatra::Delegator

        namespaces = rack_namespaces(agent)

        Rack::Builder.new do
          # Custom logger object. Rack CommonLogger does not work with cabin
          use ApiLogger, logger

          # In test env we want errors to propagate up the chain
          # so we get easy to understand test failures.
          # In production / dev we don't want a bad API endpoint
          # to crash the process
          if environment != "test"
            use ApiErrorHandler, logger
          end

          run LogStash::Api::Modules::Root.new(nil, agent)
          namespaces.each_pair do |namespace, app|
            map(namespace) do
              # Pass down a reference to the current agent
              # This allow the API to have direct access to the collector
              run app.new(nil, agent)
            end
          end
        end
      end

      def self.rack_namespaces(agent)
        {
          "/_health_report" => LogStash::Api::Modules::HealthReport,
          "/_node" => LogStash::Api::Modules::Node,
          "/_stats" => LogStash::Api::Modules::Stats,
          "/_node/stats" => LogStash::Api::Modules::NodeStats,
          "/_node/plugins" => LogStash::Api::Modules::Plugins,
          "/_node/logging" => LogStash::Api::Modules::Logging
        }
      end
    end
  end
end
