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
    include Util::Loggable

    attr_reader :logger, :config, :http_host, :http_ports, :http_environment, :agent, :port

    DEFAULT_HOST = "127.0.0.1".freeze
    DEFAULT_PORTS = (9600..9700).freeze
    DEFAULT_ENVIRONMENT = 'production'.freeze

    def self.from_settings(logger, agent, settings)
      options = {}
      options[:http_host] = settings.get('api.http.host') # may be overridden later if API configured securely
      options[:http_ports] = settings.get('api.http.port')
      options[:http_environment] = settings.get('api.environment')

      if settings.get('api.ssl.enabled')
        ssl_params = {}
        ssl_params[:keystore_path] = required_setting(settings, 'api.ssl.keystore.path', "api.ssl.enabled")
        ssl_params[:keystore_password] = required_setting(settings, 'api.ssl.keystore.password', "api.ssl.enabled")
        ssl_params[:supported_protocols] = settings.get('api.ssl.supported_protocols')
        options[:ssl_params] = ssl_params.freeze
      else
        warn_ignored(logger, settings, "api.ssl.", "api.ssl.enabled")
      end

      if settings.get('api.auth.type') == 'basic'
        auth_basic = {}
        auth_basic[:username] = required_setting(settings, 'api.auth.basic.username', "api.auth.type")
        auth_basic[:password] = required_setting(settings, 'api.auth.basic.password', "api.auth.type")

        password_policies = {}
        password_policies[:mode] = required_setting_with_changing_default(settings, 'api.auth.basic.password_policy.mode', "api.auth.type", "ERROR")
        password_policies[:length] = {}
        password_policies[:length][:minimum] = required_setting(settings, 'api.auth.basic.password_policy.length.minimum', "api.auth.type")
        if !password_policies[:length][:minimum].between?(8, 1024)
          fail(ArgumentError, "api.auth.basic.password_policy.length.minimum has to be between 8 and 1024.")
        end
        password_policies[:include] = {}
        password_policies[:include][:upper] = required_setting(settings, 'api.auth.basic.password_policy.include.upper', "api.auth.type")
        password_policies[:include][:lower] = required_setting(settings, 'api.auth.basic.password_policy.include.lower', "api.auth.type")
        password_policies[:include][:digit] = required_setting(settings, 'api.auth.basic.password_policy.include.digit', "api.auth.type")
        password_policies[:include][:symbol] = required_setting(settings, 'api.auth.basic.password_policy.include.symbol', "api.auth.type")

        auth_basic[:password_policies] = password_policies
        options[:auth_basic] = auth_basic.freeze
      else
        warn_ignored(logger, settings, "api.auth.basic.", "api.auth.type")
      end

      if !settings.set?('api.http.host')
        if settings.get('api.ssl.enabled') && settings.get('api.auth.type') == 'basic'
          logger.info("API configured securely with SSL and Basic Auth. Defaulting `api.http.host` to all available interfaces")
          options[:http_host] = '0.0.0.0'
        end
      end

      logger.debug("Initializing API WebServer",
                   "api.http.host"        => options[:http_host],
                   "api.http.port"        => settings.get("api.http.port"),
                   "api.ssl.enabled"      => settings.get("api.ssl.enabled"),
                   "api.auth.type"        => settings.get("api.auth.type"),
                   "api.environment"      => settings.get("api.environment"))

      new(logger, agent, options)
    end

    # @api internal
    def self.warn_ignored(logger, settings, pattern, trigger)
      trigger_value = settings.get(trigger)
      settings.names.each do |setting_name|
        next unless setting_name.start_with?(pattern)
        next if setting_name == trigger
        next unless settings.set?(setting_name)

        logger.warn("Setting `#{setting_name}` is ignored because `#{trigger}` is set to `#{trigger_value}`")
      end
    end

    # @api internal
    def self.required_setting(settings, setting_name, trigger)
      settings.get(setting_name) || fail(ArgumentError, "Setting `#{setting_name}` is required when `#{trigger}` is set to `#{settings.get(trigger)}`. Please provide it in your `logstash.yml`")
    end

    def self.required_setting_with_changing_default(settings, name, trigger, future_value)
      effective_value = required_setting(settings, name, trigger)
      if !settings.set?(name)
        deprecation_logger.deprecated("The default value of `#{name}` will change to `#{future_value}` in a future release of Logstash. Set it to `#{future_value}` to observe the future behavior early, or set it to `#{effective_value}` to lock in the current behavior.")
      end
      effective_value
    end

    ##
    # @param logger [Logger]
    # @param agent [Agent]
    # @param options [Hash{Symbol=>Object}]
    # @option :http_host [String]
    # @option :http_ports [Enumerable[Integer]]
    # @option :http_environment [String]
    # @option :ssl_params [Hash{Symbol=>Object}]
    #             :keystore_path [String]
    #             :keystore_password [LogStash::Util::Password]
    # @option :auth_basic [Hash{Symbol=>Object}]
    #             :username [String]
    #             :password [LogStash::Util::Password]
    def initialize(logger, agent, options = {})
      @logger = logger
      @agent = agent
      @http_host = options[:http_host] || DEFAULT_HOST
      @http_ports = options[:http_ports] || DEFAULT_PORTS
      @http_environment = options[:http_environment] || DEFAULT_ENVIRONMENT
      @ssl_params = options[:ssl_params] if options.include?(:ssl_params)
      @running = Concurrent::AtomicBoolean.new(false)
      @mutex = Mutex.new

      validate_keystore_access! if @ssl_params

      # wrap any output that puma could generate into a wrapped logger
      # use the puma namespace to override STDERR, STDOUT in that scope.
      Puma::STDERR.logger = logger
      Puma::STDOUT.logger = logger

      app = LogStash::Api::RackApp.app(logger, agent, http_environment)

      if options.include?(:auth_basic)
        username = options[:auth_basic].fetch(:username)
        password = options[:auth_basic].fetch(:password)
        password_policies = options[:auth_basic].fetch(:password_policies)
        validated_password = Setting::ValidatedPassword.new("api.auth.basic.password", password, password_policies).freeze
        app = Rack::Auth::Basic.new(app, "logstash-api") { |u, p| u == username && p == validated_password.value.value }
      end

      @app = app
    end

    def run
      logger.debug("Starting API WebServer (puma)")

      stop # Just in case

      running!

      server_thread = create_server_thread
      server_thread.join unless server_thread.nil?  # and block...
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

    def stop(options = {})
      @mutex.synchronize do
        @running.make_false
        @server.stop(true) if @server
      end
    end

    def ssl_enabled?
      !!@ssl_params
    end

    private

    def _init_server
      ::Puma::Server.new(@app, nil, log_writer: LogStash::DelegatingLogWriter.new(logger))
    end

    def create_server_thread
      server_thread = nil
      @mutex.synchronize do
        @server = _init_server
        http_ports.each_with_index do |candidate_port, idx|
          begin
            break unless running?
            @port = bind_to_port(candidate_port)
            server_thread = @server.run
            logger.info("Successfully started Logstash API endpoint", :port => candidate_port, :ssl_enabled => ssl_enabled?)
            set_http_address_metric("#{http_host}:#{candidate_port}")
            break
          rescue Errno::EADDRINUSE
            if http_ports.count == 1
              raise Errno::EADDRINUSE.new(I18n.t("logstash.web_api.cant_bind_to_port", :port => http_ports.first))
            elsif idx == http_ports.count - 1
              raise Errno::EADDRINUSE.new(I18n.t("logstash.web_api.cant_bind_to_port_in_range", :http_ports => http_ports))
            end
          end
        end
      end
      server_thread
    end

    def bind_to_port(candidate_port)
      logger.debug("Trying to start API WebServer", :port => candidate_port, :ssl_enabled => ssl_enabled?)
      if @ssl_params
        context_builder_params = {
            'keystore' => @ssl_params.fetch(:keystore_path),
            'keystore-pass' => @ssl_params.fetch(:keystore_password).value,
        }

        supported_protocols = @ssl_params.fetch(:supported_protocols, [])
        context_builder_params['protocols'] = supported_protocols if supported_protocols.any?

        ssl_context = Puma::MiniSSL::ContextBuilder.new(context_builder_params, @server.log_writer).context
        @server.add_ssl_listener(http_host, candidate_port, ssl_context)
      else
        @server.add_tcp_listener(http_host, candidate_port)
      end
      candidate_port
    end

    def set_http_address_metric(value)
      return unless @agent.metric
      @agent.metric.gauge([], :http_address, value)
    end

    # Validate access to the provided keystore.
    # Errors accessing the keystore after binding the webserver to a port are very hard to debug.
    # @api private
    def validate_keystore_access!
      return false unless @ssl_params

      raise("Password not provided!") unless @ssl_params.fetch(:keystore_password).value

      java.security.KeyStore.getInstance("JKS")
          .load(java.io.FileInputStream.new(@ssl_params.fetch(:keystore_path)),
                @ssl_params.fetch(:keystore_password).value.chars&.to_java(:char))
    rescue => e
      raise ArgumentError.new("API Keystore could not be opened (#{e})")
    end
  end
end
