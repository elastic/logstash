# encoding: utf-8

require "test_utils"
require 'logstash/namespace'
require 'logstash/inputs/kafka'
require 'logstash/errors'

describe LogStash::Inputs::Kafka do
  extend LogStash::RSpec

  before(:all) do
    jarpath = File.join(File.dirname(__FILE__), "../../vendor/jar/kafka*/libs/*.jar")
    Dir[jarpath].each do |jar|
      require jar
    end
    require 'jruby-kafka'

    # monkey patch the Kafka consumer
    class Kafka::Group
      alias orig_run run
      public
      def run(a_numThreads, a_queue)
        a_queue << "Kafka message for testing"
      end
    end
  end

  let (:kafka_config) {{"topic_id" => "test"}}

  # Extend class to control behavior. By default Kafka input will
  # loop infinitely and wait for new events to appear in the pipe
  # in this class we bail after first event
  class LogStash::Inputs::TestKafkaHarness < LogStash::Inputs::Kafka
    milestone 1

    # Max number of messages to allow before bailing out of the loop
    attr_accessor :max_num_messages
    attr_accessor :cur_num_messages

    public
    def initialize(params, max_num_messages)
      super(params)
      @max_num_messages = max_num_messages
      @cur_num_messages = 0
    end

    private
    def queue_event(msg, output_queue)
      super(msg, output_queue)
      @cur_num_messages += 1

      # need to raise exception here to stop the infinite loop
      raise LogStash::ShutdownSignal if @cur_num_messages >= @max_num_messages
    end
  end


  it 'should populate kafka config with default values' do
    kafka = LogStash::Inputs::Kafka.new(kafka_config)
    insist {kafka.zk_connect} == "localhost:2181"
    insist {kafka.topic_id} == "test"
    insist {kafka.group_id} == "logstash"
    insist {kafka.reset_beginning} == false
  end

  it "should register and load kafka jars without errors" do
    kafka = LogStash::Inputs::Kafka.new(kafka_config)
    kafka.register
  end

  it "should retrieve event from mock kafka" do
    kafka = LogStash::Inputs::TestKafkaHarness.new(kafka_config, 1)
    kafka.register

    logstash_queue = Queue.new
    kafka.run logstash_queue
    e = logstash_queue.pop
    insist { e["message"] } == "Kafka message for testing"
    # no metadata by default
    insist { e["kafka"] } == nil
  end

  it "should retrieve event from mock kafka and decorate with metadata" do
    decorate_config = {"topic_id" => "test", "decorate_events" => true}
    kafka = LogStash::Inputs::TestKafkaHarness.new(decorate_config, 1)
    kafka.register

    logstash_queue = Queue.new
    kafka.run logstash_queue
    e = logstash_queue.pop
    insist { e["message"] } == "Kafka message for testing"
    # no metadata by default
    insist { e["kafka"] } == {"msg_size"=>25, "topic"=>"test", "consumer_group"=>"logstash"}
  end

  it "should receive current events from Kafka server on localhost", :kafka => true do
    # undo the monkey patch :(
    class Kafka::Group
      alias run orig_run
      remove_method(:orig_run)
    end

    producer_options = {:broker_list => "localhost:9092",
                        :serializer_class => "kafka.serializer.StringEncoder"}
    topic = "logstash_live_kafka"
    producer = Kafka::Producer.new(producer_options)
    producer.connect()

    # send some messages to Kafka topic
    decorate_config = {"topic_id" => topic}
    producer.sendMsg(topic, nil, "this is a log line")
    producer.sendMsg(topic, nil, "this is another log line")

    kafka = LogStash::Inputs::TestKafkaHarness.new(decorate_config, 2)
    kafka.register
    logstash_queue = Queue.new
    Thread.new { kafka.run logstash_queue }
    e = logstash_queue.pop
    insist { e["message"] } == "this is a log line"

    e = logstash_queue.pop
    insist { e["message"] } == "this is another log line"
  end

end
