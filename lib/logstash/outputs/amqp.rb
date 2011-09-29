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

  # Key to route to
  config :key, :validate => :string

  # The vhost to use
  config :vhost, :validate => :string, :default => "/"

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

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
    @target = @bunny.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable)
  end # def connect

  public
  def receive(event)
    key = event.sprintf(@key) if @key
    @logger.debug(["Sending event", { :destination => to_s, :event => event, :key => key }])
    begin
      if @target
        begin
          @target.publish(event.to_json, :persistent => @persistent, :key => key)
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
    @target.publish(raw)
  end # def receive_raw

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@name}"
  end

  public
  def teardown
    @bunny.close rescue nil
    @bunny = nil
    @target = nil
    finished
  end # def teardown
end # class LogStash::Outputs::Amqp
