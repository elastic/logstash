# encoding: utf-8
require "puma"
require 'puma/single'
require 'puma/binder'
require 'puma/configuration'

class LogStash::WebServer::Base

  attr_reader :logger, :status, :config, :options

  def initialize(logger, options={})
    @logger  = logger
    @options = options
    @status  = nil

    set_environment
  end

  def run
    raise "Not implemented"
  end

  def log(str)
    logger.debug(str) if logger.debug?
  end

  def stop(options={})
    raise "Not implemented"
  end


  def setup_signals
    Signal.trap("INT") do
      @status = :exit
      stop(:graceful => true)
      exit
    end

    begin
      Signal.trap "SIGTERM" do
        stop
      end
    rescue Exception
      log "*** SIGTERM not implemented, signal based gracefully stopping unavailable!"
    end
  end

  def rackup
    File.join(File.dirname(__FILE__), "../..", "api", "config.ru") 
  end

  def cli_options
    { :rackup => rackup }
  end

  private 

  def env
    "production"
  end

  def set_environment
    @options[:environment] = env
    ENV['RACK_ENV']        = env
  end
end
