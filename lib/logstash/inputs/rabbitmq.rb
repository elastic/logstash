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
  milestone 0

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

  # Enable or disable logging
  config :debug, :validate => :boolean, :default => false

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false


  def initialize(params)
    params["codec"] = "json" if !params["codec"]

    super
  end

  # Use HotBunnies on JRuby to avoid IO#select CPU spikes
  # (see github.com/ruby-amqp/bunny/issues/95).
  #
  # On MRI, use Bunny 0.9.
  #
  # See http://rubybunny.info and http://hotbunnies.info
  # for the docs.
  if RUBY_ENGINE == "jruby"
    require "logstash/inputs/rabbitmq/hot_bunnies"

    include HotBunniesImpl
  else
    require "logstash/inputs/rabbitmq/bunny"

    include BunnyImpl
  end
end # class LogStash::Inputs::RabbitMQ
