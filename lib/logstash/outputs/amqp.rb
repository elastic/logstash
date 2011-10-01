require "logstash/outputs/base"
require "logstash/namespace"

# Push events to an AMQP exchange.
#
# AMQP is a messaging system. It requires you to run an AMQP server or 'broker'
# Examples of AMQP servers are [RabbitMQ](http://www.rabbitmq.com/) and
# [QPid](http://qpid.apache.org/)
class LogStash::Outputs::Amqp < LogStash::Outputs::Base
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

  # Key to route to by default. Defaults to queue name
  config :key, :validate => :string

  # The name of the queue to bind to the default key. Defaults to exchange name
  config :queue_name, :validate => :string

  # The vhost to use
  config :vhost, :validate => :string, :default => "/"

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

  # Is this queue durable? (aka; Should it survive a broker restart?).
  # If you omit this setting, the 'durable' property will be used as default.
  config :queue_durable, :validate => :boolean

  # Should messages persist to disk on the AMQP broker until they are read by a
  # consumer?
  config :persistent, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  public
  def register
    require "bunny" # rubygem 'bunny'
    if !MQTYPES.include?(@exchange_type)
      raise "Invalid exchange_type, #{@exchange_type.inspect}, must be one of #{MQTYPES.join(", ")}"
    end

    @queue_name ||= @name
    @queue_durable ||= @durable
    @key ||= @queue_name

    @logger.info("Registering output #{to_s}")
    connect
  end # def register

  public
  def connect
    amqpsettings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
      :logging => @debug,
    }
    amqpsettings[:user] = @user if @user
    amqpsettings[:pass] = @password.value if @password
    amqpsettings[:ssl] = @ssl if @ssl
    amqpsettings[:verify_ssl] = @verify_ssl if @verify_ssl

    begin
      @logger.debug(["Connecting to AMQP", amqpsettings, @exchange_type, @name])
      @bunny = Bunny.new(amqpsettings)
      @bunny.start
    rescue => e
      if terminating?
        return
      else
        @logger.error("AMQP connection error (during connect), will reconnect: #{e}")
        @logger.debug(["Backtrace", e.backtrace])
        sleep(1)
        retry
      end
    end

    @logger.debug("Declaring queue '#{@queue_name}' as #{"not" unless @queue_durable} durable")
    queue = @bunny.queue(@queue_name, :durable => @queue_durable)

    @logger.debug("Declaring #{@exchange_type} exchange '#{@name}' as #{"not" unless @durable} durable")
    @exchange = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)

    @logger.debug("Binding exchange '#{@name}' to key '#{@key}'")
    queue.bind(@exchange, :key => @key)
  end # def connect

  public
  def receive(event)
    key = event.sprintf(@key) if @key
    @logger.debug(["Sending event", { :destination => to_s, :event => event, :key => key }])
    begin
      if @exchange
        begin
          @exchange.publish(event.to_json, :persistent => @persistent, :key => key, :mandatory => true)
        rescue JSON::GeneratorError
          @logger.warn(["Trouble converting event to JSON", $!, event.to_hash])
          return
        end
      else
        @logger.warn("Tried to send message, but not connected to amqp yet.")
      end
    rescue *[Bunny::ServerDownError, Errno::ECONNRESET] => e
      @logger.error("AMQP connection error (during publish), will reconnect: #{e}")
      connect
      retry
    end
  end # def receive

  # This is used by the ElasticSearch AMQP/River output.
  public
  def receive_raw(raw)
    @exchange.publish(raw, :persistent => @persistent, :key => @key, :mandatory => true)
  end # def receive_raw

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@name}\##{@queue_name}"
  end

  public
  def teardown
    @bunny.close rescue nil
    @bunny = nil
    @exchange = nil
    finished
  end # def teardown
end # class LogStash::Outputs::Amqp
