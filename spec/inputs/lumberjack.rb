# encoding: utf-8
require "test_utils"
require "tempfile"

require "logstash/inputs/lumberjack"

# Mocked Lumberjack::Connection
module Lumberjack
  class Connection
    @@objects = []
    def initialize(_)
      @ack_queue = SizedQueue.new 1
      @@objects.push self
    end

    def run(&block)
      block.call({"line" => "fubar"}, nil)
      block.call({"line" => "snafu"}, nil)
      block.call({"line" => "hello world"}) do
        @ack_queue.push true
      end
    end

    def acked?
      return @ack_queue.pop
    end

    def self.acked?
      ret = @@objects.all? do |obj| obj.acked? end
      @@objects.clear
      return ret
    end
  end
end

describe LogStash::Inputs::Lumberjack do
  extend LogStash::RSpec

  describe "(non High Availability)" do
    it "should acknowledge" do
      cert = Tempfile.new "logstash-spec-input-lumberjack-cert"
      key = Tempfile.new "logstash-spec-input-lumberjack-key"

      # Mock lumberjack server so it doesn't connect to the network
      mock_lumberjack = double()
      expect(mock_lumberjack).to receive(:run) do |&block|
        block.call nil
      end

      # setup input
      input = LogStash::Inputs::Lumberjack.new "port" => 8000, "ssl_certificate" => cert.path, "ssl_key" => key.path
      input.instance_variable_set :@lumberjack, mock_lumberjack

      queue = SizedQueue.new 10
      input_thread = Thread.new do input.run(queue) end

      # check the acknowledged events got through
      insist { queue.pop["message"] } == "fubar"
      insist { queue.pop["message"] } == "snafu"
      insist { queue.pop["message"] } == "hello world"

      insist { Lumberjack::Connection.acked? } == true
      input_thread.exit
    end
    it "should handle multiple connections" do
      cert = Tempfile.new "logstash-spec-input-lumberjack-cert"
      key = Tempfile.new "logstash-spec-input-lumberjack-key"

      # Mock lumberjack server so it doesn't connect to the network
      mock_lumberjack = double()
      expect(mock_lumberjack).to receive(:run) do |&block|
        3.times do block.call nil end
      end

      # setup input
      input = LogStash::Inputs::Lumberjack.new "port" => 8000, "ssl_certificate" => cert.path, "ssl_key" => key.path
      input.instance_variable_set :@lumberjack, mock_lumberjack

      queue = SizedQueue.new(10)
      input_thread = Thread.new do input.run(queue) end

      # check we got nine events (3 connections, 3 messages each)
      9.times do queue.pop end
      insist { queue.length } == 0

      insist { Lumberjack::Connection.acked? } == true
      input_thread.exit
    end
  end

  describe "(High Availability)" do
    it "should acknowledge" do
      cert = Tempfile.new "logstash-spec-input-lumberjack-cert"
      key = Tempfile.new "logstash-spec-input-lumberjack-key"

      # Mock lumberjack server so it doesn't connect to the network
      mock_lumberjack = double()
      expect(mock_lumberjack).to receive(:run) do |&block|
        block.call nil
      end

      # setup input
      input = LogStash::Inputs::Lumberjack.new "port" => 8000,
        "ssl_certificate" => cert.path,
        "ssl_key" => key.path,
        "needs_ha" => true
      input.instance_variable_set :@lumberjack, mock_lumberjack

      queue = SizedQueue.new(10)
      input_thread = Thread.new do input.run(queue) end

      # check we got our events
      event = queue.pop
      event.trigger "filter_processed"
      insist { event["message"] } == "fubar"
      event = queue.pop
      event.trigger "filter_processed"
      insist { event["message"] } == "snafu"
      event = queue.pop
      event.trigger "filter_processed"
      insist { event["message"] } == "hello world"

      # input_thread may or may not have a bit more left to do now,
      # but we can't join it since it's an infinite loop.
      insist { Lumberjack::Connection.acked? } == true
      input_thread.exit
    end
    it "should handle multiple connections" do
      cert = Tempfile.new "logstash-spec-input-lumberjack-cert"
      key = Tempfile.new "logstash-spec-input-lumberjack-key"

      # Mock lumberjack server so it doesn't connect to the network
      mock_lumberjack = double()
      expect(mock_lumberjack).to receive(:run) do |&block|
        3.times do block.call nil end
      end

      # setup input
      input = LogStash::Inputs::Lumberjack.new "port" => 8000,
        "ssl_certificate" => cert.path,
        "ssl_key" => key.path,
        "needs_ha" => true
      input.instance_variable_set :@lumberjack, mock_lumberjack

      queue = SizedQueue.new(10)
      input_thread = Thread.new do input.run(queue) end

      # wait then check and acknowledge the events.
      9.times do
        queue.pop.trigger "filter_processed"
      end
      insist { queue.length } == 0

      # input_thread may or may not have a bit more left to do now,
      # but we can't join it since it's an infinite loop.
      insist { Lumberjack::Connection.acked? } == true
      input_thread.exit
    end
  end
end
