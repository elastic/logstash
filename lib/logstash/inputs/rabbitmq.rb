require "logstash/inputs/threadable"
require "logstash/namespace"
require "cgi" # for CGI.escape

# Pull events from a RabbitMQ exchange.
#
# The default settings will create an entirely transient queue and listen for all messages by default.
# If you need durability or any other advanced settings, please set the appropriate options
#
# This has been tested with Bunny 0.9.x, which supports RabbitMQ 2.x and 3.x. You can
# find links to both here:
#
# * RabbitMQ - <http://www.rabbitmq.com/>
# * Bunny - <https://github.com/ruby-amqp/bunny>
class LogStash::Inputs::RabbitMQ < LogStash::Inputs::Threadable

  config_name "rabbitmq"
  plugin_status "beta"

  # Custom arguments. For example, mirrored queues in RabbitMQ 2.x:  [ "x-ha-policy", "all" ]
  # RabbitMQ 3.x mirrored queues are set by policy. More information can be found
  # here: http://www.rabbitmq.com/blog/2012/11/19/breaking-things-with-rabbitmq-3-0/
  config :arguments, :validate => :array, :default => []

  # Your rabbitmq server address
  config :host, :validate => :string, :required => true

  # The rabbitmq port to connect on
  config :port, :validate => :number, :default => 5672

  # Your rabbitmq username
  config :user, :validate => :string, :default => "guest"

  # Your rabbitmq password
  config :password, :validate => :password, :default => "guest"

  # The name of the queue.
  config :queue, :validate => :string, :default => ""

  # The name of the exchange to bind the queue.
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

  # Using the prefetch_count option means that if ack is true, the server will
  # only send the number of messages specified in the prefetch_count option
  # to logstash and then the server will wait until logstash acknowledges
  # a message prior to the server sending logstash more messages.  In practice,
  # if ack is true, logstash acknowledges each message.  So increasing
  # prefetch_count might not yield any practical benefit today.
  # Must be 0 or a positive integer.
  config :prefetch_count, :validate => :number, :default => 1

  # Enable message acknowledgement. The ack only matters if prefetch_count is
  # more than 0.  Message acknowledgement improves reliablity but it reduces
  # throughput since logstash needs to tell rabbitmq-server that logstash
  # received the message.  Logstash will acknowledge only after it is able to
  # process the message into a Logstash Event
  config :ack, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false
  
  # Maximum permissible size of a frame (in bytes) to negotiate with clients
  config :frame_max, :validate => :number, :default => 131072

  # Array of headers (in messages' metadata) to add to fields in the event
  config :headers_fields, :validate => :array, :default => {}
  
  public
  def initialize(params)
    super

    @format ||= "json_event"

  end # def initialize

  public
  def register   

    @logger.info("Registering input #{@url}")
    require "bunny"
    
    @vhost ||= "/"
    @port ||= 5672
    @key ||= "#"
    
    @rabbitmq_settings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
    }
    
    @rabbitmq_settings[:user] = @user if @user
    @rabbitmq_settings[:pass] = @password.value if @password
    @rabbitmq_settings[:logging] = @debug
    @rabbitmq_settings[:ssl] = @ssl if @ssl
    @rabbitmq_settings[:verify_ssl] = @verify_ssl if @verify_ssl
    @rabbitmq_settings[:frame_max] = @frame_max if @frame_max
    
    @rabbitmq_url = "amqp://"
    if @user
      @rabbitmq_url << @user if @user
      @rabbitmq_url << ":#{CGI.escape(@password.to_s)}" if @password
      @rabbitmq_url << "@"
    end
    @rabbitmq_url += "#{@host}:#{@port}#{@vhost}/#{@queue}"

    if @prefetch_count < 0
      raise RuntimeError.new(
        "Cannot specify prefetch_count less than 0"
      )
    end
  end # def register

  def run(queue)
    begin
      @logger.debug("Connecting with RabbitMQ settings #{@rabbitmq_settings.inspect} to set up queue #{@queue.inspect}")
      @bunny = Bunny.new(@rabbitmq_settings)
      return if terminating?
      @bunny.start
      @bunny.default_channel.prefetch(@prefetch_count)

      @arguments_hash = Hash[*@arguments]

      @bunnyqueue = @bunny.queue(@queue, {:durable => @durable, :auto_delete => @auto_delete, :exclusive => @exclusive, :arguments => @arguments_hash })
      @bunnyqueue.bind(@exchange, :routing_key => @key)

      # need to get metadata from data
      @bunnyqueue.subscribe({:ack => @ack, :block => true}) do |delivery_info, metadata, data|
        
        e = to_event(data, @rabbitmq_url)
        if e          
          if !@headers_fields.empty?
            # constructing the hash array of headers to add
            # select headers from properties if they are in the array @headers_fields
            headers_add = metadata.headers.select {|k, v| @headers_fields.include?(k)}          
            @logger.debug("Headers to insert in fields : ", :headers => headers_add)
             
            headers_add.each do |added_field, added_value|
              e[added_field] = added_value              
            end # headers_add.each do
          end # if !@headers_fields.empty?
          queue << e

          # if these conditions are met, the server won't send any more
          # messages until we specifically ack this message
          # TODO(jkoppe): to improve throughput, we could ack less often
          # but, I definitely want to get community buy-in before enabling
          # one method or another.
          if @ack and @prefetch_count > 0
            @bunny.default_channel.ack(delivery_info[:delivery_tag])
          end
        end # if e
      end # @bunnyqueue.subscribe do

    rescue *[Bunny::ConnectionError, Bunny::ServerDownError] => e
      @logger.error("RabbitMQ connection error, will reconnect: #{e}")
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
end # class LogStash::Inputs::RabbitMQ
