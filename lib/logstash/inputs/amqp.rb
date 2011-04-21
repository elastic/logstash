require "logstash/inputs/base"
require "logstash/namespace"

# Pull events from an AMQP exchange.
#
# 
# TODO(sissel): Document where to learn more about AMQP and brokers.
class LogStash::Inputs::Amqp < LogStash::Inputs::Base
  MQTYPES = [ "fanout", "direct", "topic" ]

  config_name "amqp"

  # Your amqp server address
  config :host, :validate => :string, :required => true

  # The AMQP port to connect on
  config :port, :validate => :number, :default => 5672

  # Your amqp username
  config :user, :validate => :string, :default => "guest"

  # Your amqp password
  config :password, :validate => :password, :default => "guest"

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
  def initialize(params)
    super

    @mq = nil
    @debug ||= false
    @durable ||= false

    if !MQTYPES.include?(@exchange_type)
      raise "Invalid type '#{@exchange_type}' must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    require "bunny" # rubygem 'bunny'
    @logger.info("Registering input #{@url}")
    amqpsettings = {
      :vhost => (@vhost or "/"),
      :host => @host,
      :port => (@port or 5672),
    }
    amqpsettings[:user] = @user if @user
    amqpsettings[:pass] = @password if @password
    amqpsettings[:logging] = @debug
    @logger.debug("Connecting with AMQP settings #{amqpsettings.inspect} to set up #{@mqtype.inspect} queue #{@name.inspect}")
    @bunny = Bunny.new(amqpsettings)

    # TODO(sissel): Check for errors here.
    @bunny.start

    @queue = @bunny.queue(@name)
    exchange = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)
    @queue.bind(exchange)
  end # def register

  def run(queue)
    loop do
      @queue.subscribe do |data|
        begin
          obj = JSON.parse(data[:payload])
        rescue => e
          @logger.error(["json parse error", { :exception => e }])
          raise e
        end

        queue << LogStash::Event.new(obj)
      end # @queue.subscribe
    end # loop
  end # def run
end # class LogStash::Inputs::Amqp
