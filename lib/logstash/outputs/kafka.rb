# encoding: utf-8
require "logstash/outputs/base"
require "logstash/environment"
require "logstash/namespace"

# Write events to Kafka

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name "kafka"
  milestone 1

  config :topic,                   :validate => :string, :required => true
  config :broker_list,             :validate => :string, :required => true
  config :client_id,               :validate => :string, :default  => "logstash"
  config :producer_type,           :validate => :string, :default  => "async"
  config :serializer_class,        :validate => :string, :default  => "kafka.serializer.StringEncoder"
  config :queue_buffering_max_ms,  :validate => :number, :default => 100

  config :partitioner_class,       :validate => :string
  config :compression_codec,       :validate => :string
  config :send_buffer_bytes,       :validate => :number
  config :batch_num_messages,      :validate => :number
  config :retry_backoff_ms,        :validate => :number
  config :request_timeout_ms,      :validate => :number
  config :request_required_acks,   :validate => :number
  config :message_send_max_retries :validate => :number
  config :queue_enqueue_timeout_ms :validate => :number
  config :queue_buffering_max_messages,       :validate => :number
  config :topic_metadata_refresh_interval_ms, :validate => :number

  def register
    @logger.info "initializing kafka client"
    LogStash::Environment.load_kafka_jars!

    properties = java.util.Properties.new
    properties.put("metadata.broker.list",   @broker_list)
    properties.put("client.id",              @client_id)
    properties.put("producer.type",          @producer_type)
    properties.put("serializer.class",       @serializer_class)
    properties.put("queue.buffering.max.ms", @queue_buffering_max_ms)

    properties.put("partitioner.class",     @partitioner_class) if @partitioner_class
    properties.put("compression.codec",     @compression_codec) if @compression_codec
    properties.put("send.buffer.bytes",     @send_buffer_bytes) if @send_buffer_bytes
    properties.put("batch.num.messages",    @batch_num_messages) if @batch_num_messages
    properties.put("retry.backoff.ms",      @retry_backoff_ms) if @retry_backoff_ms
    properties.put("request.timeout.ms",    @request_timeout_ms) if @request_timeout_ms
    properties.put("request.required.acks", @request_required_acks) if @request_required_acks
    properties.put("message.send.max.retries", @message_send_max_retries) if @message_send_max_retries
    properties.put("queue.enqueue.timeout.ms", @queue_enqueue_timeout_ms) if @queue_enqueue_timeout_ms
    properties.put("queue.buffering.max.messages", @queue_buffering_max_messages) if @queue_buffering_max_messages
    properties.put("topic.metadata.refresh.interval.ms", @topic_metadata_refresh_interval_ms) if @topic_metadata_refresh_interval_ms

    @producer = Java::kafka.javaapi.producer.Producer.new(Java::kafka.producer.ProducerConfig.new(properties))
  end

  def receive(event)
    return unless output?(event)

    @producer.send(Java::kafka.producer.KeyedMessage.new(@topic, event.to_json))
  rescue Exception => exception
    @logger.error ['failed to publish message to kafka:', exception, exception.backtrace].join("\n")
  end
end