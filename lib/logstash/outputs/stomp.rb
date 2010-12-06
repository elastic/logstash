require "logstash/outputs/base"
require "logstash/stomp/handler"

class LogStash::Outputs::Stomp < LogStash::Outputs::Base
  attr_reader :url

  def initialize(url, config={}, &block)
    super

    @logger.debug(["Initialize", { :url => @url }])
  end # def initialize

  def register
    @logger.info(["Registering output", { :url => @url }])
    @connection = EventMachine::connect(@url.host, @url.port, LogStash::Stomp::Handler, self, @logger, @url)
  end # def register

  def receive(event)
    @logger.debug(["Sending event", { :url => @url, :event => event }])
    @connection.send(@url.path, event.to_json)
  end # def receive
end # class LogStash::Outputs::Stomp
