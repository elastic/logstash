# encoding: utf-8
require "puma"
require "puma/server"
require "sinatra"
require "rack"
require "logstash/api/rack_app"

module LogStash 
  class WebServer
    extend Forwardable

    attr_reader :logger, :status, :config, :options, :cli_options, :runner, :binder, :events, :http_host, :http_port

    def_delegator :@runner, :stats

    DEFAULT_HOST = "127.0.0.1".freeze
    DEFAULT_PORT = 9600.freeze

    def initialize(logger, options={})
      @logger      = logger
      @http_host    = options[:http_host] || DEFAULT_HOST
      @http_port    = options[:http_port] || DEFAULT_PORT
      @options     = {}
      @cli_options = options.merge({ :rackup => ::File.join(::File.dirname(__FILE__), "api", "init.ru"),
                                     :binds => ["tcp://#{http_host}:#{http_port}"],
                                     :debug => logger.debug?,
                                     # Prevent puma from queueing request when not able to properly handling them,
                                     # fixed https://github.com/elastic/logstash/issues/4674. See
                                     # https://github.com/puma/puma/pull/640 for mode internal details in PUMA.
                                     :queue_requests => false
      })
      @status      = nil
    end

    def run
      log "=== puma start: #{Time.now} ==="

      stop # Just in case

      @server = ::Puma::Server.new(LogStash::Api::RackApp.app)
      @server.add_tcp_listener(http_host, http_port)

      @server.run.join
    end

    def log(str)
      logger.debug(str)
    end

    def error(str)
      logger.error(str)
    end
    
    # Empty method, this method is required because of the puma usage we make through
    # the Single interface, https://github.com/puma/puma/blob/master/lib/puma/single.rb#L82
    # for more details. This can always be implemented when we want to keep track of this
    # bit of data.
    def write_state; end

    def stop(options={})
      @server.stop(true) if @server
    end
  end
end
