# encoding: utf-8
require "logstash/webserver"
require "puma"
require 'puma/single'
require 'puma/binder'
require 'puma/configuration'

class LogStash::WebServer::Puma < LogStash::WebServer::Base

  extend Forwardable

  attr_reader :runner, :binder, :events

  def_delegator :@runner, :stats, :stats

  def initialize(logger, options={})
    super(logger, options)
    parse_options

    @runner  = nil
    @events  = Puma::Events.strings
    @binder  = Puma::Binder.new(@events)
    @binder.import_from_env
  end

  def run
    setup_signals
    log "=== puma start: #{Time.now} ==="

    @runner = Puma::Single.new(self)
    @status = :run
    @runner.run
    stop(:graceful => true)
  end

  def error(str)
    logger.error(str) if logger.error?
  end


  def write_state

  end

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

  def parse_options
    @config = Puma::Configuration.new(cli_options)
    @config.load
    @options = @config.options
  end



end
