require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/stomp/handler"

class LogStash::Outputs::Stomp < LogStash::Outputs::Base
  attr_reader :url

  public
  def initialize(url, config={}, &block)
    super

    @logger.debug(["Initialize", { :url => @url }])
  end # def initialize

  public
  def register
    @logger.info(["Registering output", { :url => @url }])
    @connection = EventMachine::connect(@url.host, @url.port, LogStash::Stomp::Handler, self, @logger, @url)
  end # def register

  public
  def receive(event)
    @logger.debug(["Sending event", { :url => @url, :event => event }])
    @connection.send(@url.path, event.to_json)
  end # def receive
end # class LogStash::Outputs::Stomp
