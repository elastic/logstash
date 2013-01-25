require "logstash/inputs/threadable"
require "logstash/namespace"
require "cgi" # for CGI.escape

# Pull events from an AMQP exchange.
#
# <b> NOTE: THIS IS ONLY KNOWN TO WORK WITH RECENT RELEASES OF RABBITMQ. Any
# other amqp broker will not work with this plugin. I do not know why. If you
# need support for brokers other than rabbitmq, please file bugs here:
# <https://github.com/ruby-amqp/bunny> </b>
#
# The default settings will create an entirely transient queue and listen for all messages by default.
# If you need durability or any other advanced settings, please set the appropriate options
class LogStash::Inputs::Amqp < LogStash::Inputs::Threadable

  config_name "amqp"
  plugin_status "unsupported"

  # Your amqp broker's custom arguments. For mirrored queues in RabbitMQ: [ "x-ha-policy", "all" ]
  config :arguments, :validate => :array, :default => []

  # Your amqp server address
  config :host, :validate => :string, :required => true

  # The AMQP port to connect on
  config :port, :validate => :number, :default => 5672

  # Your amqp username
  config :user, :validate => :string, :default => "guest"

  # Your amqp password
  config :password, :validate => :password, :default => "guest"

  # The name of the queue. Depricated due to conflicts with puppet naming convention.
  # Replaced by 'queue' variable. See LOGSTASH-755
  config :name, :validate => :string, :deprecated => true

  # The name of the queue.
  config :queue, :validate => :string, :default => ""

  # The name of the exchange to bind the queue. This is analogous to the 'amqp
  # output' [config 'name'](../outputs/amqp)
  config :exchange, :validate => :string, :required => true

  # The routing key to use. This is only valid for direct or fanout exchanges
  #
  # * Routing keys are ignored on topic exchanges.
  # * Wildcards are not valid on direct exchanges.
  config :key, :validate => :string, :default => "logstash"

  # The vhost to use. If you don't know what this is, leave the default.
  config :vhost, :validate => :string, :default => "/"

  # Passive queue creation? Useful for checking queue existance without modifying server state
  config :passive, :validate => :boolean, :default => false

  # Is this queue durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => false

  # Should the queue be deleted on the broker when the last consumer
  # disconnects? Set this option to 'false' if you want the queue to remain
  # on the broker, queueing up messages until a consumer comes along to
  # consume them.
  config :auto_delete, :validate => :boolean, :default => true

  # Is the queue exclusive? (aka: Will other clients connect to this named queue?)
  config :exclusive, :validate => :boolean, :default => true

  # Prefetch count. Number of messages to prefetch
  config :prefetch_count, :validate => :number, :default => 1

  # Enable message acknowledgement
  config :ack, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  public
  def initialize(params)
    super

    @format ||= "json_event"

  end # def initialize

  public
  def register

    if @name
      if @queue
        @logger.error("'name' and 'queue' are the same setting, but 'name' is deprecated. Please use only 'queue'")
      end
      @queue = @name
    end   

    @logger.info("Registering input #{@url}")
    require "bunny" # rubygem 'bunny'
    @vhost ||= "/"
    @port ||= 5672
    @key ||= "#"
    @amqpsettings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
    }
    @amqpsettings[:user] = @user if @user
    @amqpsettings[:pass] = @password.value if @password
    @amqpsettings[:logging] = @debug
    @amqpsettings[:ssl] = @ssl if @ssl
    @amqpsettings[:verify_ssl] = @verify_ssl if @verify_ssl
    @amqpurl = "amqp://"
    if @user
      @amqpurl << @user if @user
      @amqpurl << ":#{CGI.escape(@password.to_s)}" if @password
      @amqpurl << "@"
    end
    @amqpurl += "#{@host}:#{@port}#{@vhost}/#{@queue}"
  end # def register

  def run(queue)
    begin
      @logger.debug("Connecting with AMQP settings #{@amqpsettings.inspect} to set up queue #{@queue.inspect}")
      @bunny = Bunny.new(@amqpsettings)
      return if terminating?
      @bunny.start
      @bunny.qos({:prefetch_count => @prefetch_count})

      @arguments_hash = Hash[*@arguments]

      @bunnyqueue = @bunny.queue(@queue, {:durable => @durable, :auto_delete => @auto_delete, :exclusive => @exclusive, :arguments => @arguments_hash })
      @bunnyqueue.bind(@exchange, :key => @key)

      @bunnyqueue.subscribe({:ack => @ack}) do |data|
        e = to_event(data[:payload], @amqpurl)
        if e
          queue << e
        end
      end # @bunnyqueue.subscribe

    rescue *[Bunny::ConnectionError, Bunny::ServerDownError] => e
      @logger.error("AMQP connection error, will reconnect: #{e}")
      # Sleep for a bit before retrying.
      # TODO(sissel): Write 'backoff' method?
      sleep(1)
      retry
    end # begin/rescue
  end # def run

  def teardown
    @bunnyqueue.unsubscribe unless @durable == true
    @bunnyqueue.delete unless @durable == true
    @bunny.close if @bunny
    finished
  end # def teardown
end # class LogStash::Inputs::Amqp
