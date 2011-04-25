require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Amqp < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "direct", "topic" ]

  config_name "amqp"

  # Your amqp server address
  config :host, :validate => :string, :required => true, :default => "localhost"

  # The AMQP port to connect on
  config :port, :validate => :number, :default => 5672

  # Your amqp username
  config :user, :validate => :string, :required => true, :default => "guest"

  # Your amqp password
  config :password, :validate => :string, :required => true, :default => "guest"

  # The exchange type (fanout, topic, direct)
  config :exchange_type, :validate => :string, :required => true

  # The name of the exchange
  config :name, :validate => :string, :required => true

  # The vhost to use
  config :vhost, :validate => :string, :default => "/"

  # Is this exchange durable?
  config :durable, :validate => :boolean, :default => false

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require "bunny" # rubygem 'bunny'
    if !MQTYPES.include?(@exchange_type)
      raise "Invalid exchange_type, #{@exchange_type.inspect}, must be one of #{MQTYPES.join(", ")}"
    end

    @logger.info("Registering output #{to_s}")
    amqpsettings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port
    }
    amqpsettings[:user] = @user if @user
    amqpsettings[:pass] = @password if @password
    amqpsettings[:logging] = @debug
    @logger.debug(["Connecting to AMQP", amqpsettings, @exchange_type, @name])
    @bunny = Bunny.new(amqpsettings)
    @bunny.start

    @target = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)
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
