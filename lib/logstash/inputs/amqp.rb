require "amqp" # rubygem 'amqp'
require "logstash/inputs/base"
require "logstash/namespace"
require "mq" # rubygem 'amqp'
require "uuidtools" # rubygem 'uuidtools'

class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

  public
  def initialize(url, type, config={}, &block)
    super

    @mq = nil

    # Handle path /<type>/<name>
    unused, @mqtype, @name = @url.path.split("/", 3)
    if @mqtype == nil or @name == nil
      raise "amqp urls must have a path of /<type>/name where <type> is #{MQTYPES.join(", ")}"
    end

    if !MQTYPES.include?(@mqtype)
      raise "Invalid type '#{@mqtype}' must be one of #{MQTYPES.JOIN(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering input #{@url}")
    amqpsettings = {
      :host => @url.host,
      :port => (@url.port or 5672),
    }
    amqpsettings[:user] = @url.user if @url.user
    amqpsettings[:pass] = @url.password if @url.password
    @amqp = AMQP.connect(amqpsettings)
    @mq = MQ.new(@amqp)
    @target = nil

    @target = @mq.queue(UUIDTools::UUID.timestamp_create)
    case @mqtype
      when "fanout"
        #@target.bind(MQ.fanout(@url.path, :durable => true))
        @target.bind(@mq.fanout(@name))
      when "direct"
        @target.bind(@mq.direct(@name))
      when "topic"
        @target.bind(@mq.topic(@name))
    end # case @mqtype

    @target.subscribe(:ack => true) do |header, message|
      event = LogStash::Event.from_json(message)
      receive(event)
      header.ack
    end
  end # def register
end # class LogStash::Inputs::Amqp
