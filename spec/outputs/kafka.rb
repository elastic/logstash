# encoding: utf-8

require 'rspec'
require 'insist'
require 'logstash/namespace'
require "logstash/timestamp"
require 'logstash/outputs/kafka'

describe LogStash::Outputs::Kafka do

  let (:kafka_config) {{"topic_id" => "test"}}

  it 'should populate kafka config with default values' do
    kafka = LogStash::Outputs::Kafka.new(kafka_config)
    insist {kafka.broker_list} == "localhost:9092"
    insist {kafka.topic_id} == "test"
    insist {kafka.compression_codec} == "none"
    insist {kafka.serializer_class} == "kafka.serializer.StringEncoder"
    insist {kafka.partitioner_class} == "kafka.producer.DefaultPartitioner"
    insist {kafka.producer_type} == "sync"
  end

  it "should register and load kafka jars without errors" do
    kafka = LogStash::Outputs::Kafka.new(kafka_config)
    kafka.register
  end

  it "should send logstash event to kafka broker" do
    timestamp = LogStash::Timestamp.now
    expect_any_instance_of(Kafka::Producer)
    .to receive(:send_msg)
        .with("test", nil, "{\"message\":\"hello world\",\"host\":\"test\",\"@timestamp\":\"#{timestamp}\",\"@version\":\"1\"}")
    e = LogStash::Event.new({"message" => "hello world", "host" => "test", "@timestamp" => timestamp})
    kafka = LogStash::Outputs::Kafka.new(kafka_config)
    kafka.register
    kafka.receive(e)
  end

end
