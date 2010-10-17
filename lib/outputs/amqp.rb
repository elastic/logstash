require "logstash/namespace"
require "logstash/event"
require "uri"
require "amqp" # rubygem 'amqp'
require "mq" # rubygem 'amqp'

class LogStash::Outputs::Amqp
  TYPES = [ "fanout", "queue", "topic" ]
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
    @mq = nil

    # Handle path /<type>/<name>
    unused, @type, @name = @url.path.split("/", 3)
    if @type == nil or @name == nil
      raise "amqp urls must have a path of /<type>/name where <type> is #{TYPES.join(", ")}"
    end

    if !TYPES.include?(@type)
      raise "Invalid type '#{@type}' must be one #{TYPES.join(", ")}"
    end
  end # def initialize

  def register
    @amqp = AMQP.connect(:host => @url.host)
    @mq = MQ.new(@amqp)
    @target = nil

    case @type
      when "fanout"
        @target = @mq.fanout(@url.path)
      when "direct"
        @target = @mq.direct(@url.path)
      when "topic"
        @target = @mq.topic(@url.path)
    end # case @type
  end # def register

  def receive(event)
    @target.publish(event.to_json)
  end # def event
end # class LogStash::Outputs::Amqp
