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

require "logstash/api/rack_app"
require "puma"
require "puma/server"
require "logstash/patches/puma"
require "concurrent"
require "thread"

module LogStash
  class WebServer

    attr_reader :logger, :config, :http_host, :http_ports, :http_environment, :agent

    DEFAULT_HOST = "127.0.0.1".freeze
    DEFAULT_PORTS = (9600..9700).freeze
    DEFAULT_ENVIRONMENT = 'production'.freeze

    def self.from_settings(logger, agent, settings)
      options = {}
      options[:http_host] = settings.get('api.http.host')
      options[:http_ports] = settings.get('api.http.port')
      options[:http_environment] = settings.get('api.environment')


      logger.debug("Initializing API WebServer",
                   "api.http.host"        => settings.get("api.http.host"),
                   "api.http.port"        => settings.get("api.http.port"),
                   "api.environment"      => settings.get("api.environment"))

      new(logger, agent, options)
    end

    ##
    # @param logger [Logger]
    # @param agent [Agent]
    # @param options [Hash{Symbol=>Object}]
    # @option :http_host [String]
    # @option :http_ports [Enumerable[Integer]]
    # @option :http_environment [String]
    def initialize(logger, agent, options={})
      @logger = logger
      @agent = agent
      @http_host = options[:http_host] || DEFAULT_HOST
      @http_ports = options[:http_ports] || DEFAULT_PORTS
      @http_environment = options[:http_environment] || DEFAULT_ENVIRONMENT
      @running = Concurrent::AtomicBoolean.new(false)

      # wrap any output that puma could generate into a wrapped logger
      # use the puma namespace to override STDERR, STDOUT in that scope.
      Puma::STDERR.logger = logger
      Puma::STDOUT.logger = logger

      @app = LogStash::Api::RackApp.app(logger, agent, http_environment)
    end

    def run
      logger.debug("Starting API WebServer (puma)")

      stop # Just in case

      running!

      bind_to_available_port # and block...

      logger.debug("API WebServer has stopped running")
    end

    def running!
      @running.make_true
    end

    def running?
      @running.value
    end

    def address
      "#{http_host}:#{@port}"
    end

    def stop(options={})
      @running.make_false
      @server.stop(true) if @server
    end

    private

    def _init_server
      io_wrapped_logger = LogStash::IOWrappedLogger.new(logger)
      events = ::Puma::Events.new(io_wrapped_logger, io_wrapped_logger)

      ::Puma::Server.new(@app, events)
    end

    def bind_to_available_port
      http_ports.each_with_index do |candidate_port, idx|
        begin
          break unless running?

          @server = _init_server

          logger.debug("Trying to start API WebServer", :port => candidate_port)
          @server.add_tcp_listener(http_host, candidate_port)

          @port = candidate_port
          logger.info("Successfully started Logstash API endpoint", :port => candidate_port)
          set_http_address_metric("#{http_host}:#{candidate_port}")

          break
        rescue Errno::EADDRINUSE
          if http_ports.count == 1
            raise Errno::EADDRINUSE.new(I18n.t("logstash.web_api.cant_bind_to_port", :port => http_ports.first))
          elsif idx == http_ports.count-1
            raise Errno::EADDRINUSE.new(I18n.t("logstash.web_api.cant_bind_to_port_in_range", :http_ports => http_ports))
          end
        end
      end
    end

    def set_http_address_metric(value)
      return unless @agent.metric
      @agent.metric.gauge([], :http_address, value)
    end
  end
end
