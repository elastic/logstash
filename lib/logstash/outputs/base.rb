require "cgi"
require "logstash/event"
require "logstash/logging"
require "logstash/plugin"
require "logstash/namespace"
require "logstash/config/mixin"
require "uri"

class LogStash::Outputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  attr_accessor :logger

  config_name "output"

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDOUT)
    config_init(params)
  end

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end # def receive

  public
  def handle(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end

    receive(event)
  end # def handle
end # class LogStash::Outputs::Base
