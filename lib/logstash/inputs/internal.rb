
require "logstash/inputs/base"
require "eventmachine-tail"
require "socket" # for Socket.gethostname

class LogStash::Inputs::Internal < LogStash::Inputs::Base
  attr_reader :channel

  def initialize(url, type, config={}, &block)
    super

    # Default host to the machine's hostname if it's not set
    @url.host ||= Socket.gethostname
    @channel = EventMachine::Channel.new
  end

  def register
    @logger.info("Registering input #{@url}")
    @channel.subscribe do |event|
      receive(event)
    end
  end # def register

  def receive(event)
    if !event.is_a?(LogStash::Event)
      event = LogStash::Event.new({
        "@message" => event,
        "@type" => @type,
        "@tags" => @tags.clone,
        "@source" => @url,
      })
    end
    @logger.debug(["Got event", event])
    @callback.call(event)
  end # def receive
end # class LogStash::Inputs::Internal
