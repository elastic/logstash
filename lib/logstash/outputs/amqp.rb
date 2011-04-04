require "bunny" # rubygem 'bunny'
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Amqp < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "direct", "topic" ]

  config_name "amqp"
  config :host, :validate => :string
  config :user, :validate => :string
  config :pass, :validate => :string
  config :exchange_type, :validate => :string
  config :name, :validate => :string
  config :vhost, :validate => :string
  config :durable, :validate => :boolean
  config :debug, :validate => :boolean

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

    @target = @bunny.exchange9@name, :type => @exchange_type.to_sym, :durable => @durable)
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
