# encoding: utf-8
require "puma"
require 'puma/single'
require 'puma/binder'
require 'puma/configuration'
require 'puma/commonlogger'

module LogStash 
  class WebServer

  extend Forwardable

  attr_reader :logger, :status, :config, :options, :cli_options, :runner, :binder, :events

  def_delegator :@runner, :stats

  def initialize(logger, options={})
    @logger      = logger
    @options     = {}
    @cli_options = options.merge({ :rackup => ::File.join(::File.dirname(__FILE__), "api", "init.ru")  })
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
    logger.debug(str) if logger.debug?
  end

  def error(str)
    logger.error(str) if logger.error?
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
    end
    @status = :stop
    log "=== puma shutdown: #{Time.now} ==="
  end

  private 

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
end; end
