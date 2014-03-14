# encoding: utf-8
require "logstash/inputs/threadable"
require "logstash/namespace"

# Pull events from a RabbitMQ exchange.
#
# The default settings will create an entirely transient queue and listen for all messages by default.
# If you need durability or any other advanced settings, please set the appropriate options
#
# This has been tested with Bunny 0.9.x, which supports RabbitMQ 2.x and 3.x. You can
# find links to both here:
#
# * RabbitMQ - <http://www.rabbitmq.com/>
# * March Hare: <http://rubymarchhare.info>
# * Bunny - <https://github.com/ruby-amqp/bunny>
class LogStash::Inputs::RabbitMQ < LogStash::Inputs::Threadable

  config_name "rabbitmq"
  milestone 1

  #
  # Connection
  #

  # RabbitMQ server address
  config :host, :validate => :string, :required => true

  # RabbitMQ port to connect on
  config :port, :validate => :number, :default => 5672

  # RabbitMQ username
  config :user, :validate => :string, :default => "guest"

  # RabbitMQ password
  config :password, :validate => :password, :default => "guest"

  # The vhost to use. If you don't know what this is, leave the default.
  config :vhost, :validate => :string, :default => "/"

  # Enable or disable SSL
  config :ssl, :validate => :boolean, :default => false

  # Validate SSL certificate
  config :verify_ssl, :validate => :boolean, :default => false

  # Enable or disable logging
  config :debug, :validate => :boolean, :default => false, :deprecated => "Use the logstash --debug flag for this instead."



  #
  # Queue & Consumer
  #

  # The name of the queue Logstash will consume events from.
  config :queue, :validate => :string, :default => ""

  # Is this queue durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => false

  # Should the queue be deleted on the broker when the last consumer
  # disconnects? Set this option to 'false' if you want the queue to remain
  # on the broker, queueing up messages until a consumer comes along to
  # consume them.
  config :auto_delete, :validate => :boolean, :default => false

  # Is the queue exclusive? Exclusive queues can only be used by the connection
  # that declared them and will be deleted when it is closed (e.g. due to a Logstash
  # restart).
  config :exclusive, :validate => :boolean, :default => false

  # Extra queue arguments as an array.
  # To make a RabbitMQ queue mirrored, use: {"x-ha-policy" => "all"}
  config :arguments, :validate => :array, :default => {}

  # Prefetch count. Number of messages to prefetch
  config :prefetch_count, :validate => :number, :default => 256

  # Enable message acknowledgement
  config :ack, :validate => :boolean, :default => true

  # Passive queue creation? Useful for checking queue existance without modifying server state
  config :passive, :validate => :boolean, :default => false



  #
  # (Optional) Exchange binding
  #

  # Optional.
  #
  # The name of the exchange to bind the queue to.
  config :exchange, :validate => :string

  # Optional.
  #
  # The routing key to use when binding a queue to the exchange.
  # This is only relevant for direct or topic exchanges.
  #
  # * Routing keys are ignored on fanout exchanges.
  # * Wildcards are not valid on direct exchanges.
  config :key, :validate => :string, :default => "logstash"


  def initialize(params)
    params["codec"] = "json" if !params["codec"]

    super
  end

  # Use March Hare on JRuby to avoid IO#select CPU spikes
  # (see github.com/ruby-amqp/bunny/issues/95).
  #
  # On MRI, use Bunny.
  #
  # See http://rubybunny.info and http://rubymarchhare.info
  # for the docs.
  if RUBY_ENGINE == "jruby"
    require "logstash/inputs/rabbitmq/march_hare"

    include MarchHareImpl
  else
    require "logstash/inputs/rabbitmq/bunny"

    include BunnyImpl
  end
end # class LogStash::Inputs::RabbitMQ
