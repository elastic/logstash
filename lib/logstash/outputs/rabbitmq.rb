require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/util/amqp/driver"

# Push events to a RabbitMQ exchange.
#
# This plugin uses Bunny 0.9.x when running with mri and
# host_bunnies 1.4.x when running under jruby.
#
# * RabbitMQ - <http://www.rabbitmq.com/>
# * Bunny - <https://github.com/ruby-amqp/bunny>
# * HotBunnies - <https://github.com/ruby-amqp/hot_bunnies>
class LogStash::Outputs::RabbitMQ < LogStash::Outputs::Base
  MQTYPES = [ "fanout", "direct", "topic" ]

  config_name "rabbitmq"
  plugin_status "beta"


  # Your rabbitmq server address
  config :host, :validate => :string, :default => "localhost"

  # The rabbitmq port to connect on
  config :port, :validate => :number, :default => 5672

  # Your rabbitmq username
  config :user, :validate => :string, :default => "guest"

  # Your rabbitmq password
  config :password, :validate => :password, :default => "guest"

  # The vhost to use. If you don't know what this is, leave the default.
  config :vhost, :validate => :string, :default => "/"

  # The name of the exchange to bind the queue.
  config :exchange, :validate => :string, :default => "logstash"

  # Exchange type, must be either fanout, direct or topic.
  config :exchange_type, :validate => [ "fanout", "direct", "topic"], :default => "direct"

  # Options for exchange decalration. By default, performance is valued over event durability.
  config :exchange_opts, :validate => :hash, :default => {
      "durable" => false,
      "auto_delete" => false,
      "passive" => false,
  }

  # The routing key to use. This is only valid for direct or topic exchanges
  #
  # * Routing keys are ignored on fanout exchanges.
  # * Wildcards are not valid on direct exchanges.
  config :routing_key, :validate => :string, :default => "logstash"

  # Should the event be persisted to disk when it arrives in a queue.
  # Note that this can considerably impact performance and only works if
  # it is consumed by a durable queue.
  config :persistent, :validate => :boolean, :default => false

  # Prefetch count. Number of messages to accept before acknowledgment.
  config :prefetch_count, :validate => :number, :default => 1

  # Enable message acknowledgement
  config :ack, :validate => :boolean, :default => false

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  # Maximum permissible size of a frame (in bytes) to negotiate with clients
  config :frame_max, :validate => :number, :default => 131072

  public
  def register
    @logger.info("Registering output", :plugin => self)

    @rabbitmq_settings = {
        :vhost => @vhost,
        :host => @host,
        :port => @port,
        :logging => @debug,
    }
    @rabbitmq_settings[:user] = @user if @user
    @rabbitmq_settings[:pass] = @password.value if @password
    @rabbitmq_settings[:ssl] = @ssl if @ssl
    @rabbitmq_settings[:verify_ssl] = @verify_ssl if @verify_ssl
    @rabbitmq_settings[:frame_max] = @frame_max if @frame_max

    @driver = LogStash::Rabbitmq.driver_class.new(@rabbitmq_settings)
    @driver.setup_output(
        :exchange => @exchange,
        :exchange_type => @exchange_type,
        :exchange_opts => @exchange_opts,
        :prefetch_count => @prefetch_count,
        :ack => @ack,
        :persistent => @persistent
    )
  end # def register


  public
  def receive(event)
    return unless output?(event)


    key = event.sprintf(@routing_key)
    @logger.debug("Sending event", :destination => to_s, :event => event,
                  :routing_key => key)
    begin
      @driver.publish(event.to_json, :routing_key => key)
    rescue JSON::GeneratorError => e
      @logger.warn("Trouble converting event to JSON", :exception => e,
                   :event => event)
      return
    end
  end # def receive

  public
  def to_s
    "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@exchange}\##{@key}"
  end

  public
  def teardown
    @driver.destroy
    finished
  end # def teardown
end # class LogStash::Outputs::RabbitMQ
