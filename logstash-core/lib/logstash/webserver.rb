# encoding: utf-8
require "puma"
require "puma/single"
require "puma/binder"
require "puma/configuration"
require "puma/commonlogger"

module LogStash 
  class WebServer

    class HostBindingError < StandardError; end

    extend Forwardable

    attr_reader :logger, :status, :config, :options, :cli_options, :runner, :binder, :events

    def_delegator :@runner, :stats

    DEFAULT_PORT_RANGE=(9600...9700).freeze

    def initialize(logger, options={})
      @logger      = logger
      http_host    = options[:http_host]
      http_port    = options[:http_port] || pick_default_port(http_host, DEFAULT_PORT_RANGE)
      @options     = {}
      @cli_options = options.merge({ :rackup => ::File.join(::File.dirname(__FILE__), "api", "init.ru"),
                                     :binds => ["tcp://#{http_host}:#{http_port}"],
                                     :debug => logger.debug?,
                                     # Prevent puma from queueing request when not able to properly handling them,
                                     # fixed https://github.com/elastic/logstash/issues/4674. See
                                     # https://github.com/puma/puma/pull/640 for mode internal details in PUMA.
                                     :queue_requests => false
      })

      logger.terminal("Binding Logstash WebAPI to tcp://#{http_host}:#{http_port}")

      @status      = nil
      parse_options

      @runner  = nil
      @events  = ::Puma::Events.strings
      @binder  = ::Puma::Binder.new(@events)
      @binder.import_from_env

      set_environment
    end

    def run
      log "=== puma start: #{Time.now} ==="

      @runner = Puma::Single.new(self)
      @status = :run
      @runner.run
      stop(:graceful => true)
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
      graceful = options.fetch(:graceful, true)

      if graceful
        @runner.stop_blocked
      else
        @runner.stop
      end rescue nil

      @status = :stop
      log "=== puma shutdown: #{Time.now} ==="
    end

    private

    def pick_default_port(http_host, range=(9600...9700))
      range.step(1) do |current_port|
        begin
          TCPServer.new(http_host, current_port)
          return current_port
        rescue Errno::EADDRINUSE
        end
      end
      raise HostBindingError.new("Range #{range} is full")
    end

    def env
      @options[:debug] ? "development" : "production"
    end

    def set_environment
      @options[:environment] = env
      ENV['RACK_ENV']        = env
    end

    def parse_options
      @config  = ::Puma::Configuration.new(cli_options)
      @config.load
      @options = @config.options
    end
  end
end
