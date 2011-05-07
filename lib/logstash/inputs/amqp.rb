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
  config :exchange_type, :validate => [ "fanout", "direct", "topic"], :required => true

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

    if !MQTYPES.include?(@exchange_type)
      raise "Invalid type '#{@exchange_type}' must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering input #{@url}")
    require "bunny" # rubygem 'bunny'
    @amqpsettings = {
      :vhost => (@vhost or "/"),
      :host => @host,
      :port => (@port or 5672),
    }
    @amqpsettings[:user] = @user if @user
    @amqpsettings[:pass] = @password.value if @password
    @amqpsettings[:logging] = @debug
  end # def register

  def run(queue)
    loop do
      @logger.debug("Connecting with AMQP settings #{@amqpsettings.inspect} to set up #{@mqtype.inspect} queue #{@name.inspect}")
      @bunny = Bunny.new(@amqpsettings)

      begin
        @bunny.start

        @queue = @bunny.queue(@name)
        exchange = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)
        @queue.bind(exchange)

        @queue.subscribe do |data|
          begin
            obj = JSON.parse(data[:payload])
          rescue => e
            @logger.error(["json parse error", { :exception => e }])
            raise e
          end

          queue << LogStash::Event.new(obj)
        end # @queue.subscribe
      rescue *[Bunny::ConnectionError, Bunny::ServerDownError] => e
        @logger.error("AMQP connection error, will reconnect: #{e}")
        # Sleep for a bit before retrying.
        # TODO(sissel): Write 'backoff' method?
        sleep(1)
      end # begin/rescue
    end # loop
  end # def run
end # class LogStash::Inputs::Amqp
