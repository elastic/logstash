# encoding: utf-8
require "logstash/outputs/base"
require "logstash/environment"
require "logstash/namespace"
require "timeout"

# Write events to Kafka
# todo: add write batching support

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name "kafka"
  milestone 1

  config  :serializer_class, :validate => :string, :default  => "kafka.serializer.StringEncoder"
  config  :broker_list,      :validate => :string, :required => true
  config  :timeout,          :validate => :number, :default  => 60
  config  :topic,            :validate => :string, :required => true

  def register
    @logger.info "initializing kafka client"
    LogStash::Environment.load_kafka_jars!

    properties = java.util.Properties.new
    properties.put("serializer.class",     @serializer_class)
    properties.put("metadata.broker.list", @broker_list)

    @producer = Java::kafka.javaapi.producer.Producer.new(Java::kafka.producer.ProducerConfig.new(properties))
  end

  def receive(event)
    return unless output?(event)

    Timeout::timeout(@timeout) do
      @producer.send(Java::kafka.producer.KeyedMessage.new(@topic, event.to_json))
    end
  rescue Exception => exception
    @logger.error ['failed to publish message to kafka:', exception, exception.backtrace].join("\n")
  end
end