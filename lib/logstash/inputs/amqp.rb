require "logstash/inputs/base"
require "logstash/namespace"

# Pull events from an AMQP exchange.
#
# AMQP is a messaging system. It requires you to run an AMQP server or 'broker'
# Examples of AMQP servers are [RabbitMQ](http://www.rabbitmq.com/) and
# [QPid](http://qpid.apache.org/)
#
# The default settings will create an entirely transient queue and listen for all messages by default.
# If you need durability or any other advanced settings, please set the appropriate options
class LogStash::Inputs::Amqp < LogStash::Inputs::Base

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

  # The name of the queue. 
  config :name, :validate => :string, :default => ""

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
  # Disabling this can greatly increase speed
  # at the expense of possible duplicate messages
  config :ack, :validate => :boolean, :default => true

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
  def initialize(params)
    super

    @format ||= "json_event"

  end # def initialize

  public
  def register
    require "logstash/util/amqp"
    @logger.info("Registering input #{@url}")
    self.class.send(:include, LogStash::Util::AMQP)
    @driver ||= select_driver
    @logger.info("Logstash driver selected", :driver => driver)
    require "#{@driver}"
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
    amqp_credentials = ""
    amqp_credentials << @user if @user
    amqp_credentials << ":#{@password}" if @password
    @amqpurl += amqp_credentials unless amqp_credentials.nil?
    @amqpurl += "#{@host}:#{@port}#{@vhost}/#{@name}"

    @metric_amqp_read = @logger.metrics.timer(self, "amqp-read")
    @metric_queue_write = @logger.metrics.timer(self, "internal-queue-write")
  end # def register

  def run(queue)
    begin
      @logger.debug("Connecting with AMQP settings #{@amqpsettings.inspect} to set up queue #{@name.inspect}")
      @connection = connect(@driver, @amqpsettings)
      return if terminating?
      @channel = start!(@driver, @connection, @prefetch_count)

      @queue = @channel.queue(@name, {:durable => @durable, :auto_delete => @auto_delete, :exclusive => @exclusive})
      do_bind(@driver, @queue, @exchange, @key)

      timer = @metric_amqp_read.time
      if @driver == 'hot_bunnies'
        subscription = @queue.subscribe(:ack => @ack, :blocking => true) do |headers,data|
          timer.stop
          e = to_event(data, @amqp_url)
          if e
            @metric_queue_write.time do
              queue << e
              headers.ack if @ack == true # ack after we know we're good
            end
          end
          time = @metric_amqp_read.time
        end # @queue.subscribe
      else
        @queue.subscribe({:ack => @ack}) do |data|
          timer.stop
          e = to_event(data[:payload], @amqpurl)
          if e
            @metric_queue_write.time do
              queue << e
            end
          end
          timer = @metric_amqp_read.time
        end # @queue.subscribe
      end # @driver.subscribe

    rescue Exception => e
      @logger.error("AMQP connection error: #{e}")
      # Sleep for a bit before retrying.
      # TODO(sissel): Write 'backoff' method?
      sleep(1)
      retry
    end # begin/rescue
  end # def run

  def teardown
    do_unbind(@driver, @queue, @exchange, @key) unless @durable == true
    @queue.unsubscribe unless @durable == true
    @queue.delete unless @durable == true
    @bunny.close if @bunny
    finished
  end # def teardown
end # class LogStash::Inputs::Amqp
