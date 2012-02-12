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
  plugin_status "beta"

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

  # Key to route to by default. Defaults to 'logstash'
  #
  # * Routing keys are ignored on topic exchanges.
  config :key, :validate => :string, :default => "logstash"

  # The vhost to use
  config :vhost, :validate => :string, :default => "/"

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

  # Should the exchange be deleted on the broker when the last producer 
  # disconnects? Set this option to 'false' if you want the exchange to remain
  # on the broker. If set to true, queues attempting to bind before it is
  # created will fail.
  config :auto_delete, :validate => :boolean, :default => true

  # Should messages persist to disk on the AMQP broker until they are read by a
  # consumer?
  config :persistent, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  # Driver selection
  # By default, logstash will use the `hot_bunnies` gem under JRuby
  # and the `bunny` gem under MRI/YARV variants
  # If you need to explcitly set this, do so here
  # see [choosing a driver](choosing-a-driver) for more information
  # Please note that currently, `hot_bunnies` does not yet
  # support SSL. If you need SSL, please explicitly set this to
  # `bunny`
  config :driver, :validate => ["bunny", "hot_bunnies"]

  public
  def register
    require "logstash/util/amqp" # rubygem 'bunny'
    @logger.info("Registering output", :plugin => self)
    self.class.send(:include, LogStash::Util::AMQP)
    @driver ||= select_driver
    @logger.info("Logstash driver selected", :driver => driver)
    require "#{@driver}"

    @amqpsettings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
      :logging => @debug,
    }
    @amqpsettings[:user] = @user if @user
    @amqpsettings[:pass] = @password.value if @password
    @amqpsettings[:ssl] = @ssl if @ssl
    @amqpsettings[:verify_ssl] = @verify_ssl if @verify_ssl

    do_it # THIS WILL CONFLICT WITH THE AMQP HELPER
  end # def register

  public
  def do_it
    begin
      @logger.debug("Connecting to AMQP", :settings => @amqpsettings,
                    :exchange_type => @exchange_type, :name => @name)
      @connection = connect(@driver, @amqpsettings)
      @channel = start!(@driver, @connection, nil)
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

    @logger.debug("Declaring exchange", :name => @name, :type => @exchange_type,
                  :durable => @durable)
    @exchange = @channel.exchange(@name, :type => @exchange_type.to_sym, :durable => @durable, :auto_delete => @auto_delete)

    @logger.debug("Binding exchange", :name => @name, :key => @key)
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
      if @exchange
        @logger.debug(["Publishing message", { :destination => to_s, :message => message, :key => key }])
        # TODO (lusis)
        # Move options building to the helper
        # Luckily both libs use similar approaches
        case @driver
        when 'hot_bunnies'
          publish_opts = {:routing_key => key, :properties => {:persistent => @persistent}}
        else
          publish_opts = {:key => key, :persistent => @persistent}
        end
        @exchange.publish(message, publish_opts)
      else
        @logger.warn("Tried to send message, but not connected to amqp yet.")
      end
    rescue Exception => e
      @logger.error("AMQP connection error (during publish), will reconnect: #{e}")
      connect
      retry
    end
  end

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@name}\##{@key}"
  end

  public
  def teardown
    if driver == 'bunny'
      @channel.close rescue nil
    end
    @connection = nil
    @exchange = nil
    finished
  end # def teardown
end # class LogStash::Outputs::Amqp
