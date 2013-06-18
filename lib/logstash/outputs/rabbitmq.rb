require "logstash/outputs/base"
require "logstash/namespace"

# Push events to a RabbitMQ exchange.
#
# This has been tested with Bunny 0.9.x, which supports RabbitMQ 2.x and 3.x. You can
# find links to both here:
#
# * RabbitMQ - <http://www.rabbitmq.com/>
# * Bunny - <https://github.com/ruby-amqp/bunny>
class LogStash::Outputs::RabbitMQ < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "direct", "topic" ]

  config_name "rabbitmq"
  milestone 0

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
  config :exchange, :validate => :string, :required => true

  # Key to route to by default. Defaults to 'logstash'
  #
  # * Routing keys are ignored on fanout exchanges.
  config :key, :validate => :string, :default => "logstash"

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

    @logger.info("Registering output", :plugin => self)
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
      @logger.debug("Connecting to AMQP", :settings => amqpsettings,
                    :exchange_type => @exchange_type, :name => @exchange)
      @bunny = Bunny.new(amqpsettings)
      @bunny.start
    rescue => e
      if terminating?
        return
      else
        @logger.error("AMQP connection error (during connect), will reconnect",
                      :exception => e, :backtrace => e.backtrace)
        sleep(1)
        retry
      end
    end

    @logger.debug("Declaring exchange", :name => @exchange, :type => @exchange_type,
                  :durable => @durable)
    @bunnyexchange = @bunny.exchange(@exchange, :type => @exchange_type.to_sym, :durable => @durable)

    @logger.debug("Binding exchange", :name => @exchange, :key => @key)
  end # def connect

  public
  def receive(event)
    return unless output?(event)

    @logger.debug("Sending event", :destination => to_s, :event => event,
                  :key => key)
    key = event.sprintf(@key) if @key
    begin
      receive_raw(event.to_json, key)
    rescue JSON::GeneratorError => e
      @logger.warn("Trouble converting event to JSON", :exception => e,
                   :event => event)
      return
    end
  end # def receive

  public
  def receive_raw(message, key=@key)
    begin
      if @bunnyexchange
        @logger.debug(["Publishing message", { :destination => to_s, :message => message, :key => key }])
        @bunnyexchange.publish(message, :persistent => @persistent, :key => key)
      else
        @logger.warn("Tried to send message, but not connected to amqp yet.")
      end
    rescue *[Bunny::ServerDownError, Errno::ECONNRESET] => e
      @logger.error("AMQP connection error (during publish), will reconnect: #{e}")
      connect
      retry
    end
  end

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@exchange}\##{@key}"
  end

  public
  def teardown
    @bunny.close rescue nil
    @bunny = nil
    @bunnyexchange = nil
    finished
  end # def teardown
end # class LogStash::Outputs::RabbitMQ
