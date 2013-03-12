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
  
  # Maximum permissible size of a frame (in bytes) to negotiate with clients
  config :frame_max, :validate => :number, :default => 131072

  # Array of headers (in messages' metadata) to add to fields in the event
  config :headers2fields, :validate => :array, :default => {}
  
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
  end # def register

  def run(queue)
    begin
      @logger.debug("Connecting with RabbitMQ settings #{@rabbitmq_settings.inspect} to set up queue #{@queue.inspect}")
      @bunny = Bunny.new(@rabbitmq_settings)
      return if terminating?
      @bunny.start
      @bunny.qos({:prefetch_count => @prefetch_count})

      @arguments_hash = Hash[*@arguments]

      @bunnyqueue = @bunny.queue(@queue, {:durable => @durable, :auto_delete => @auto_delete, :exclusive => @exclusive, :arguments => @arguments_hash })
      @bunnyqueue.bind(@exchange, :key => @key)

      # need to get metadata from data
      @bunnyqueue.subscribe({:ack => @ack}) do |delivery_info, metadata, data|
        
        e = to_event(data, @rabbitmq_url)
        if e          
          if !@headers2fields.empty?
            # constructing the hash array of headers to add
            # select headers from properties if they are in the array @headers2fields
            headers2add = metadata.headers.select {|k, v| @headers2fields.include?(k)}          
            @logger.debug("Headers to insert in fields : #{headers2add.inspect}")
             
            # This doesn't work
            #e.fields.merge(headers2add)
            
            headers2add.each do |added_field, added_value|
              e[added_field] = added_value                        
            end # headers2add.each do
          end # if !@headers2fields.empty?
          queue << e
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
