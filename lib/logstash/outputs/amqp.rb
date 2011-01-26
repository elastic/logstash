require "amqp" # rubygem 'amqp'
require "logstash/outputs/base"
require "logstash/namespace"
require "mq" # rubygem 'amqp'

class LogStash::Outputs::Amqp < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

  public
  def initialize(url, config={}, &block)
    super

    # Handle path /<type>/<name>
    unused, @mqtype, @name = @url.path.split("/", 3)
    if @mqtype == nil or @name == nil
      raise "amqp urls must have a path of /<type>/name where <type> is #{MQTYPES.join(", ")}"
    end

    if !MQTYPES.include?(@mqtype)
      raise "Invalid type '#{@mqtype}' must be one #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering output #{@url}")
    amqpsettings = {
      :host => @url.host,
      :port => (@url.port or 5672),
    }
    amqpsettings[:user] = @url.user if @url.user
    amqpsettings[:pass] = @url.password if @url.password
    @amqp = AMQP.connect(amqpsettings)
    @mq = MQ.new(@amqp)
    @target = nil

    case @mqtype
      when "fanout"
        @target = @mq.fanout(@name)
      when "queue"
        @target = @mq.queue(@name, :durable => @urlopts["durable"] ? true : false)
      when "topic"
        @target = @mq.topic(@name)
    end # case @mqtype
  end # def register

  public
  def receive(event)
    @logger.debug(["Sending event", { :url => @url, :event => event }])
    @target.publish(event.to_json)
  end # def receive

  # This is used by the ElasticSearch AMQP/River output.
  public
  def receive_raw(raw)
    if @target == nil
      raise "had trouble registering AMQP URL #{@url.to_s}, @target is nil"
    end

    @target.publish(raw)
  end # def receive_raw
end # class LogStash::Outputs::Amqp
