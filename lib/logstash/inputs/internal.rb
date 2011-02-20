require "eventmachine-tail"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::Internal < LogStash::Inputs::Base
  attr_reader :channel

  config_name "internal"

  public
  def initialize(params)
    super
    raise "issue/17: needs refactor to support configfile"

    # Default host to the machine's hostname if it's not set
    @url.host ||= Socket.gethostname
    @channel = EventMachine::Channel.new
  end

  public
  def register
    @logger.info("Registering input #{@url}")
    @channel.subscribe do |event|
      receive(event)
    end
  end # def register

  public
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
