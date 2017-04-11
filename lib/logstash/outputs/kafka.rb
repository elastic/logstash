# encoding: utf-8
require "logstash/outputs/base"
require "logstash/environment"
require "logstash/namespace"
require "json"

# Write events to Kafka

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name "kafka"
  milestone 1

  # kafka logstash ouput options
  config :topic,                    :validate => :string,  :required => true
  config :kafka_home,               :validate => :string,  :required => true
  config :log_stats,                :validate => :boolean, :default  => true
  config :log_stats_interval,       :validate => :number,  :default  => 120
  config :log_stats_level,          :validate => ["info", "debug"], :default => "info"

  # non-default kafka producer options
  config :client_id,                :validate => :string,  :default  => "logstash"
  config :producer_type,            :validate => ["sync", "async"], :default => "async"
  config :metadata_broker_list,     :validate => :string,  :required => true
  config :serializer_class,         :validate => :string,  :default  => "kafka.serializer.StringEncoder"
  config :queue_buffering_max_ms,   :validate => :number,  :default  => 100

  # configurable kafka producer options
  config :partitioner_class,        :validate => :string
  config :compression_codec,        :validate => :string
  config :send_buffer_bytes,        :validate => :number
  config :batch_num_messages,       :validate => :number
  config :retry_backoff_ms,         :validate => :number
  config :request_timeout_ms,       :validate => :number
  config :request_required_acks,    :validate => :number
  config :message_send_max_retries, :validate => :number
  config :queue_enqueue_timeout_ms, :validate => :number
  config :queue_buffering_max_messages,       :validate => :number
  config :topic_metadata_refresh_interval_ms, :validate => :number

  def register
    raise(LogStash::EnvironmentError, "JRuby is required to ouput to Kafka") unless LogStash::Environment.jruby?
    @logger.info "initializing kafka client"
    load_kafka

    # setup producer
    producer_properties = [
      "client.id",
      "metadata.broker.list", 
      "producer.type",
      "serializer.class",
      "partitioner.class",
      "compression.codec",
      "send.buffer.bytes",
      "batch.num.messages",
      "retry.backoff.ms",
      "request.timeout.ms",
      "request.required.acks",
      "message.send.max.retries",
      "queue.enqueue.timeout.ms",
      "queue.buffering.max.ms",
      "queue.buffering.max.messages",
      "topic.metadata.refresh.interval.ms" 
    ].reduce(java.util.Properties.new) do |properties, key|
      value = property_value key

      if value
        properties.put key, value.to_s
        @logger.debug "setting kafka producer property: " + key + " => " + value.to_s
      end

      properties
    end

    @producer = Java::kafka.javaapi.producer.Producer.new(Java::kafka.producer.ProducerConfig.new(producer_properties))
  end

  def receive(event)
    return unless output?(event)

    @producer.send(Java::kafka.producer.KeyedMessage.new(@topic, event.to_json))

    counters[:messages_sent] += 1
    log_stats if should_log_stats?
  rescue Exception => exception
    counters[:flush_errors] += 1
    @logger.error ['failed to publish message to kafka:', exception, exception.backtrace].join("\n")
  end

  private
  def load_kafka
    # find kafka jars
    kafka_jars = Dir.glob(::File.join(@kafka_home, "*.jar"))
    raise(LogStash::EnvironmentError, "Could not find Kafka jar files under #{@kafka_home}") if kafka_jars.empty?

    # load kafka jars
    kafka_jars.each do |jar|
      logger.debug case require jar
      when true
        "required jar: " + jar
      else
        "failed to require jar: " + jar
      end
    end
  end

  def counters reset = false
    @counters = Hash.new 0 if reset or @counters.nil?
    @counters
  end

  def should_log_stats?
    if @log_stats and Time.now.to_i > @last_stats_log_time.to_i + @log_stats_interval and not counters.empty?
      true
    end
  end

  def log_stats
    @last_stats_log_time = Time.now
    @logger.send(@log_stats_level.downcase.to_sym, "kafka events: " + counters.to_json)

    # reset counters
    counters(true)
  rescue Exception => exception
    puts exception
  end

  def property_value property_key
    property_instance_key = "@" + property_key.gsub('.', '_') if property_key.kind_of? String

    if self.instance_variable_defined? property_instance_key
      self.instance_variable_get property_instance_key
    end
  end
end