require "logstash/outputs/base"
require "logstash/namespace"

# Write events to a [Kafka](http://kafka.apache.org/) cluster.
#
# This output plugin has been tested with Kafka 0.8.0-beta1 and needs a fully
# configured Kafka setup to work.
# See [Kafka documentation](http://kafka.apache.org/documentation.html) for
# details.
class LogStash::Outputs::Kafka < LogStash::Outputs::Base

  config_name "kafka"
  milestone 1

  default :codec, "json"

  # A list of Kafka brokers to connect to.
  #
  # Example:
  #
  #     output {
  #       hosts => ["broker1:9092", "broker2:9092"]
  #     }
  config :hosts, :validate => :array, :required => true

  # The consumer client id.
  config :client_id, :validate => :string, :default => "logstash_client"

  # The topic where events will be published to.
  config :topic, :validate => :string, :default => "logstash"

  public
  def register
    require 'poseidon'

    @logger.info("Registering output", :plugin => self)

    @producer = Poseidon::Producer.new(@hosts, @client_id)

    @codec.on_event do |payload|
      send_payload(payload)
    end
  end

  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end
    @codec.encode(event)
  end

  private
  def send_payload(payload)
    # This might block if the Kafka cluster is not setup correctly.
    # TODO(bernd): Figure out how to work around that.
    if !@producer.send_messages([Poseidon::MessageToSend.new(@topic, payload)])
      @logger.warn("Unable to connect to Kafka cluster, dropping payload.",
                   :payload => payload, :hosts => @hosts)
    end
  end

end # class LogStash::Outputs::Kafka
