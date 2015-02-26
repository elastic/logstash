# encoding: utf-8
require "test_utils"
require "logstash/outputs/rabbitmq"
require "march_hare"

describe LogStash::Outputs::RabbitMQ do
  extend LogStash::RSpec

  describe "Without HA" do
    config <<-CONFIG
      input {
        generator {
          count => 1
        }
      }
      output {
        rabbitmq {
          host => "host"
          exchange_type => "topic"
          exchange => "fu"
          key => "bar"
        }
      }
    CONFIG

    it "should publish data to RabbitMQ" do
      exchange = double("exchange")
      conn = double("conn")
      channel = double("channel")

      expect(MarchHare).to receive(:connect).with({
         :vhost => "/",
         :host => "host",
         :port => 5672,
         :user => "guest",
         :pass => "guest",
         :automatic_recovery => false
      }).and_return conn
      expect(conn).to receive(:create_channel).and_return channel
      expect(channel).to receive(:exchange).with("fu", {
        :type => :topic,
        :durable => true
      }).and_return exchange

      expect(exchange).to receive(:publish).with(an_instance_of(String), {
        :routing_key => "bar",
        :properties => { :persistent => true }
      })

      expect(conn).to receive(:open?).and_return true
      expect(conn).to receive(:close)

      # Run this scenario
      pipeline = LogStash::Pipeline.new(config)
      pipeline.run
    end
  end

  describe "with HA" do
    config <<-CONFIG
      input {
        generator {
          count => 1
        }
      }
      output {
        rabbitmq {
          host => "host"
          exchange_type => "topic"
          exchange => "fu"
          key => "bar"
          provides_ha => true
        }
      }
    CONFIG

    it "should publish data to RabbitMQ" do
      exchange = double("exchange")
      conn = double("conn")
      channel = double("channel")

      expect(MarchHare).to receive(:connect).with({
        :vhost => "/",
        :host => "host",
        :port => 5672,
        :user => "guest",
        :pass => "guest",
        :automatic_recovery => false
      }).and_return conn
      expect(conn).to receive(:create_channel).and_return channel
      expect(channel).to receive(:exchange).with("fu", {
        :type => :topic,
        :durable => true
      }).and_return exchange
      # This call enables HA in RabbitMQ
      expect(channel).to receive(:confirm_select)
##      # This call confirms that HA is enabled.
##      expect(channel).to receive(:using_publisher_confirmations?).and_return true

      expect(exchange).to receive(:publish).with(an_instance_of(String), {
        :routing_key => "bar",
        :properties => { :persistent => true }
      })
      # This call blocks until the acknowledgements come back.
      expect(channel).to receive(:wait_for_confirms).and_return true

      expect(conn).to receive(:open?).and_return true
      expect(conn).to receive(:close)

      # Run this scenario
      pipeline = LogStash::Pipeline.new(config)
      pipeline.run
    end
  end

  describe "HA state changes" do
    it "should not be triggered for non-HA RabbitMQ output." do
      # Create the output.
      output = LogStash::Outputs::RabbitMQ.new(
        "host" => "host",
        "exchange_type" => "topic",
        "exchange" => "fu",
        "key" => "bar",
      )

      # Setup expected MarchHare calls.
      exchange = double("exchange")
      conn = double("conn")
      channel = double("channel")

      expect(MarchHare).to receive(:connect).with({
        :vhost => "/",
        :host => "host",
        :port => 5672,
        :user => "guest",
        :pass => "guest",
        :automatic_recovery => false
      }).and_return conn
      expect(conn).to receive(:create_channel).and_return channel
      expect(channel).to receive(:exchange).with("fu", {
        :type => :topic,
        :durable => true
      }).and_return exchange

      expect(exchange).to receive(:publish).with(an_instance_of(String), {
        :routing_key => "bar",
        :properties => { :persistent => true }
      })

      expect(conn).to receive(:open?).and_return true
      expect(conn).to receive(:close)

      # Setup event
      event = LogStash::Event.new("Hello" => "World")
      passed = true
      event.on "filter_processed" do
        passed = false
      end
      event.on "output_sent" do
        passed = false
      end

      # Run the scenario manually.
      output.register
      output.receive(event)


      insist { passed } == true
      output.teardown
    end

    it "should be triggered for HA RabbitMQ output." do
      # Create the output.
      output = LogStash::Outputs::RabbitMQ.new(
        "host" => "host",
        "exchange_type" => "topic",
        "exchange" => "fu",
        "key" => "bar",
        "provides_ha" => "true"
      )

      # Setup expected MarchHare calls.
      exchange = double("exchange")
      conn = double("conn")
      channel = double("channel")

      expect(MarchHare).to receive(:connect).with({
        :vhost => "/",
        :host => "host",
        :port => 5672,
        :user => "guest",
        :pass => "guest",
        :automatic_recovery => false
      }).and_return conn
      expect(conn).to receive(:create_channel).and_return channel
      expect(channel).to receive(:exchange).with("fu", {
        :type => :topic,
        :durable => true
      }).and_return exchange
      # This call enables HA in RabbitMQ
      expect(channel).to receive(:confirm_select)
##      # This call confirms that HA is enabled.
##      expect(channel).to receive(:using_publisher_confirmations?).and_return true

      expect(exchange).to receive(:publish).with(an_instance_of(String), {
        :routing_key => "bar",
        :properties => { :persistent => true }
      })
      # This call blocks until the acknowledgements come back.
      expect(channel).to receive(:wait_for_confirms).and_return true

      expect(conn).to receive(:open?).and_return true
      expect(conn).to receive(:close)

      # Setup event
      event = LogStash::Event.new("Hello" => "World")
      actions = []
      event.on "filter_processed" do
        actions.push "filter_processed"
      end
      event.on "output_sent" do
        actions.push "output_sent"
      end

      # Run the scenario manually.
      output.register
      output.receive(event)

      # Expected event behaviour
      insist { actions } == ["filter_processed"]
      event.trigger "output_send"
      insist { actions } == ["filter_processed", "output_sent"]


      output.teardown
    end
    it "should not be triggered for failed send" do
      # Create the output.
      output = LogStash::Outputs::RabbitMQ.new(
        "host" => "host",
        "exchange_type" => "topic",
        "exchange" => "fu",
        "key" => "bar",
        "provides_ha" => "true"
      )

      # Setup expected MarchHare calls.
      exchange = double("exchange")
      conn = double("conn")
      channel = double("channel")

      expect(MarchHare).to receive(:connect).with({
        :vhost => "/",
        :host => "host",
        :port => 5672,
        :user => "guest",
        :pass => "guest",
        :automatic_recovery => false
      }).and_return conn
      expect(conn).to receive(:create_channel).and_return channel
      expect(channel).to receive(:exchange).with("fu", {
        :type => :topic,
        :durable => true
      }).and_return exchange
      # This call enables HA in RabbitMQ
      expect(channel).to receive(:confirm_select)
##      # This call confirms that HA is enabled.
##      expect(channel).to receive(:using_publisher_confirmations?).and_return true

      expect(exchange).to receive(:publish).with(an_instance_of(String), {
        :routing_key => "bar",
        :properties => { :persistent => true }
      })
      # This call blocks until the acknowledgements come back.
      # Returning false indicates that the message has been nacked.
      expect(channel).to receive(:wait_for_confirms).and_return false

      expect(conn).to receive(:open?).and_return true
      expect(conn).to receive(:close)

      # Setup event
      event = LogStash::Event.new("Hello" => "World")
      actions = []
      event.on "filter_processed" do
        actions.push "filter_processed"
      end
      event.on "output_sent" do
        actions.push "output_sent"
      end

      # Run the scenario manually.
      output.register
      output.receive(event)

      # Expected event behaviour
      insist { actions } == ["filter_processed"]
      event.trigger "output_send"
      # Output sent should never be called since send failed.
      insist { actions } == ["filter_processed"]


      output.teardown
    end
  end
end
