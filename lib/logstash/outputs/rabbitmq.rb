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
  plugin_status "beta"

  # Your rabbitmq server address
  config :host, :validate => :string, :required => true

  # The rabbitmq port to connect on
  config :port, :validate => :number, :default => 5672

  # Your rabbitmq username
  config :user, :validate => :string, :default => "guest"

  # Your rabbitmq password
  config :password, :validate => :password, :default => "guest"

  # The name of the exchange
  config :exchange, :validate => :string, :required => true
  
  # The exchange type (fanout, topic, direct)
  config :exchange_type, :validate => [ "fanout", "direct", "topic"], :required => true

  # Key to route to by default. Defaults to 'logstash'
  #
  # * Routing keys are ignored on fanout exchanges.
  config :key, :validate => :string, :default => "logstash"

  # The vhost to use
  config :vhost, :validate => :string, :default => "/"

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

  # Should messages persist to disk on the rabbitmq broker until they are read by a
  # consumer?
  config :persistent, :validate => :boolean, :default => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  # Maximum permissible size of a frame (in bytes) to negotiate with clients
  config :frame_max, :validate => :number, :default => 131072

  # Array of fields to add to headers in messages' metadata
  config :fields_headers, :validate => :array, :default => {}
  
  public
  def register
    require "bunny"

    @logger.info("Registering output", :plugin => self)
    connect
  end # def register

  public
  def connect
    
    rabbitmq_settings = {
      :vhost => @vhost,
      :host => @host,
      :port => @port,
      :logging => @debug,
    }
    rabbitmq_settings[:user] = @user if @user
    rabbitmq_settings[:pass] = @password.value if @password
    rabbitmq_settings[:ssl] = @ssl if @ssl
    rabbitmq_settings[:verify_ssl] = @verify_ssl if @verify_ssl
    rabbitmq_settings[:frame_max] = @frame_max if @frame_max

    begin
      @logger.debug("Connecting to RabbitMQ", :settings => rabbitmq_settings,
                    :exchange_type => @exchange_type, :name => @exchange)
      @bunny = Bunny.new(rabbitmq_settings)
      @bunny.start
    rescue => e
      if terminating?
        return
      else
        @logger.error("RabbitMQ connection error (during connect), will reconnect",
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
    
   
    # Adding headers from fields' attribute
    @headers_add = event.fields.select {|k, v| @fields_headers.include?(k)}
    @logger.debug("Adding headers from Fields attributes : #{@headers_add.inspect}")
            
    # Adding headers from "original" attributes 
    # Iteration on each field name specified in fields_headers
    @fields_headers.each do |added_field|
      # Verify if added_field is in the list of tags     
      if event.include?(added_field)
        @headers_add[added_field] = event[added_field]
        @logger.debug("Adding native field #{added_field} to headers")
      else
        @logger.debug("Not Adding tag #{added_field} to headers because missing")
      end # if event.include?(added_field)
    end # :fields_headers.each do |added_field|
    
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
        if @headers_add.empty?
          #tags2headers is empty, so we send the message normally
          @logger.debug(["Publishing message", { :destination => to_s, :message => message, :key => key }])
          @bunnyexchange.publish(message, :persistent => @persistent, :key => key)
        else
          #publishing messages WITH headers, that are stored in "headers_add"
          @logger.debug(["Publishing message", { :destination => to_s, :message => message, :key => key , :headers => @headers_add.inspect}])
          @bunnyexchange.publish(message, :persistent => @persistent, :key => key, :headers => @headers_add)
          
        end # if @headers2headers.empty?
      else
        @logger.warn("Tried to send message, but not connected to rabbitmq yet.")
      end  # if @bunnyexchange
    rescue *[Bunny::ServerDownError, Errno::ECONNRESET] => e
      @logger.error("RabbitMQ connection error (during publish), will reconnect: #{e}")
      connect
      retry
    end # begin
  end # def receive_raw

  public
  def to_s
    return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@exchange}\##{@key}"
  end # def to_s

  public
  def teardown
    @bunny.close rescue nil
    @bunny = nil
    @bunnyexchange = nil
    finished
  end # def teardown
end # class LogStash::Outputs::RabbitMQ
