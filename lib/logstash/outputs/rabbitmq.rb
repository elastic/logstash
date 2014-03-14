# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Push events to a RabbitMQ exchange. Requires RabbitMQ 2.x
# or later version (3.x is recommended).
#
# Relevant links:
#
# * RabbitMQ: <http://www.rabbitmq.com/>
# * March Hare: <http://rubymarchhare.info>
# * Bunny: <http://rubybunny.info>
class LogStash::Outputs::RabbitMQ < LogStash::Outputs::Base
  EXCHANGE_TYPES = ["fanout", "direct", "topic"]

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
  # Exchange
  #


  # The exchange type (fanout, topic, direct)
  config :exchange_type, :validate => EXCHANGE_TYPES, :required => true

  # The name of the exchange
  config :exchange, :validate => :string, :required => true

  # Key to route to by default. Defaults to 'logstash'
  #
  # * Routing keys are ignored on fanout exchanges.
  config :key, :validate => :string, :default => "logstash"

  # Is this exchange durable? (aka; Should it survive a broker restart?)
  config :durable, :validate => :boolean, :default => true

  # Should RabbitMQ persist messages to disk?
  config :persistent, :validate => :boolean, :default => true



  def initialize(params)
    params["codec"] = "json" if !params["codec"]

    super
  end

  # Use MarchHare on JRuby to avoid IO#select CPU spikes
  # (see github.com/ruby-amqp/bunny/issues/95).
  #
  # On MRI, use Bunny.
  #
  # See http://rubybunny.info and http://rubymarchhare.info
  # for the docs.
  if RUBY_ENGINE == "jruby"
    require "logstash/outputs/rabbitmq/march_hare"

    include MarchHareImpl
  else
    require "logstash/outputs/rabbitmq/bunny"

    include BunnyImpl
  end
end # class LogStash::Outputs::RabbitMQ
