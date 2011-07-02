require "logstash/inputs/base"
require "logstash/namespace"

# Pull events from an AMQP exchange.
#
# AMQP is a messaging system. It requires you to run an AMQP server or 'broker'
# Examples of AMQP servers are [RabbitMQ](http://www.rabbitmq.com/) and 
# [QPid](http://qpid.apache.org/)
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

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  public
  def initialize(params)
    super

    @format ||= ["json_event"]

    if !MQTYPES.include?(@exchange_type)
      raise "Invalid type '#{@exchange_type}' must be one of #{MQTYPES.join(", ")}"
    end
  end # def initialize

  public
  def register
    @logger.info("Registering input #{@url}")
    require "bunny" # rubygem 'bunny'
    @vhost ||= "/"
    @port ||= 5672
    @amqpsettings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
    }
    @amqpsettings[:user] = @user if @user
    @amqpsettings[:pass] = @password.value if @password
    @amqpsettings[:logging] = @debug
    @amqpurl = "amqp://"
    if @user or @password
      @amqpurl += "#{@user}:xxxxxx@"
    end
    @amqpurl += "#{@host}:#{@port}#{@vhost}/#{@name}"
  end # def register

  def run(queue)
    begin
      @logger.debug("Connecting with AMQP settings #{@amqpsettings.inspect} to set up #{@mqtype.inspect} queue #{@name.inspect}")
      @bunny = Bunny.new(@amqpsettings)
      return if terminating?
      @bunny.start

      @queue = @bunny.queue(@name, :durable => @durable)
      exchange = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)
      @queue.bind(exchange)

      @queue.subscribe do |data|
        e = to_event(data[:payload], @amqpurl)
        if e
          queue << e
        end
      end # @queue.subscribe
    rescue *[Bunny::ConnectionError, Bunny::ServerDownError] => e
      @logger.error("AMQP connection error, will reconnect: #{e}")
      # Sleep for a bit before retrying.
      # TODO(sissel): Write 'backoff' method?
      sleep(1)
      retry
    end # begin/rescue
  end # def run

  def teardown
    @bunny.close if @bunny
  end # def teardown
end # class LogStash::Inputs::Amqp
