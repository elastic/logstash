require "logstash/inputs/base"
require "amqp" # rubygem 'amqp'
require "mq" # rubygem 'amqp'
require "uuidtools" # rubygem 'uuidtools'

class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

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
  end

  def register
    @amqp = AMQP.connect(:host => @url.host)
    @mq = MQ.new(@amqp)
    @target = nil

    @target = @mq.queue(UUIDTools::UUID.timestamp_create)
    case @mqtype
      when "fanout"
        #@target.bind(MQ.fanout(@url.path, :durable => true))
        @target.bind(MQ.fanout(@name))
      when "direct"
        @target.bind(MQ.direct(@name))
      when "topic"
        @target.bind(MQ.topic(@name))
    end # case @mqtype

    @target.subscribe(:ack => true) do |header, message|
      event = LogStash::Event.from_json(message)
      receive(event)
      header.ack
    end
  end # def register
end # class LogStash::Inputs::Amqp
