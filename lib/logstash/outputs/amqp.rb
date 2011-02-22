require "bunny" # rubygem 'bunny'
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Amqp < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "queue", "topic" ]

  config_name "amqp"
  config :host => :string
  config :user => :string
  config :pass => :string
  config :exchange_type => :string
  config :name => :string
  config :vhost => :string
  config :durable => :boolean
  config :debug => :boolean

  public
  def initialize(params)
    super

    @debug ||= false
    @durable ||= false

    if !MQTYPES.include?(@exchange_type)
      raise "Invalid exchange_type, #{@exchange_type.inspect}, must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering output #{to_s}")
    amqpsettings = {
      :vhost => (@vhost or "/"),
      :host => @host,
      :port => (@port or 5672),
    }
    amqpsettings[:user] = @user if @user
    amqpsettings[:pass] = @pass if @pass
    amqpsettings[:logging] = @debug
    @logger.debug(["Connecting to AMQP", amqpsettings, @exchange_type, @name])
    @bunny = Bunny.new(amqpsettings)
    @bunny.start

    @target = nil
    case @exchange_type
      when "fanout"
        @target = @bunny.exchange(@name, :type => :fanout)
      when "queue"
        @target = @bunny.exchange(@name, :type => :direct)
      when "topic"
        @target = @bunny.exchange(@name, :type => :topic)
    end # case @exchange_type
  end # def register

  public
  def receive(event)
    @logger.debug(["Sending event", { :destination => to_s, :event => event }])
    @target.publish(event.to_json)
  end # def receive

  # This is used by the ElasticSearch AMQP/River output.
  public
  def receive_raw(raw)
    @target.publish(raw)
  end # def receive_raw

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@name}"
  end
end # class LogStash::Outputs::Amqp
