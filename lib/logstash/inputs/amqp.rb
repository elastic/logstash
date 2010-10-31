require "logstash/inputs/base"
require "amqp" # rubygem 'amqp'
require "mq" # rubygem 'amqp'
require "uuidtools" # rubygem 'uuidtools'

class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  TYPES = [ "fanout", "queue", "topic" ]

  def initialize(url, config={}, &block)
    super

    @mq = nil

    # Handle path /<type>/<name>
    unused, @type, @name = @url.path.split("/", 3)
    if @type == nil or @name == nil
      raise "amqp urls must have a path of /<type>/name where <type> is #{TYPES.join(", ")}"
    end

    if !TYPES.include?(@type)
      raise "Invalid type '#{@type}' must be one of #{TYPES.JOIN(", ")}"
    end
  end

  def register
    @amqp = AMQP.connect(:host => @url.host)
    @mq = MQ.new(@amqp)
    @target = nil

    @target = @mq.queue(UUIDTools::UUID.timestamp_create)
    case @type
      when "fanout"
        #@target.bind(MQ.fanout(@url.path, :durable => true))
        @target.bind(MQ.fanout(@url.path))
      when "direct"
        @target.bind(MQ.direct(@url.path))
      when "topic"
        @target.bind(MQ.topic(@url.path))
    end # case @type

    @target.subscribe(:ack => true) do |header, message|
      event = LogStash::Event.from_json(message)
      receive(event)
      header.ack
    end
  end # def register
end # class LogStash::Inputs::Amqp
