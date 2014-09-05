# encoding: utf-8

require "test_utils"
require 'logstash/namespace'
require 'logstash/inputs/kafka'
require 'logstash/errors'

describe LogStash::Inputs::Kafka do
  extend LogStash::RSpec

  let (:kafka_config) {{"topic_id" => "test"}}

  config <<-CONFIG
    input {
      kafka {
        zk_connect => "localhost:2181"
        topic_id => "logstash_test11"
      }
    }
  CONFIG

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

  it "should retrieve event from kafka" do
    # Extend class to control behavior
    class LogStash::Inputs::TestKafka < LogStash::Inputs::Kafka
      milestone 1
      private
      def queue_event(msg, output_queue)
        super(msg, output_queue)
        # need to raise exception here to stop the infinite loop
        raise LogStash::ShutdownSignal
      end
    end

    kafka = LogStash::Inputs::TestKafka.new(kafka_config)
    kafka.register

    class Kafka::Group
      public
      def run(a_numThreads, a_queue)
        a_queue << "Kafka message"
      end
    end

    logstash_queue = Queue.new
    kafka.run logstash_queue
    e = logstash_queue.pop
    insist { e["message"] } == "Kafka message"
    # no metadata by default
    insist { e["kafka"] } == nil
  end

  it "should receive current events from Kafka server on localhost", :kafka => true do
    jarpath = File.join(File.dirname(__FILE__), "../../vendor/jar/kafka*/libs/*.jar")
    Dir[jarpath].each do |jar|
      require jar
    end
    require 'jruby-kafka'
    producer_options = {:broker_list => "localhost:9092",
                        :serializer_class => "kafka.serializer.StringEncoder"}
    producer = Kafka::Producer.new(producer_options)
    producer.connect()

    # send some messages to Kafka topic
    producer.sendMsg("logstash_test11", nil, "this is a log line")
    producer.sendMsg("logstash_test11", nil, "this is another log line")

    pipeline = LogStash::Pipeline.new(config)
    queue = Queue.new
    pipeline.instance_eval do
      @output_func = lambda { |event| queue << event }
    end
    # start LS
    pipeline_thread = Thread.new { pipeline.run }

    event = queue.pop
    puts event.to_s
    insist { event["message"] } == "foobar"
    pipeline_thread.join
  end

end
