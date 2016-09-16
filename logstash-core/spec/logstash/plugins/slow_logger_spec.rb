# encoding: utf-8
require "spec_helper"
require "logstash/plugin"
require "logstash/outputs/base"
require "logstash/codecs/base"
require "logstash/inputs/base"
require "logstash/filters/base"

describe "slowlog interface" do

  let(:logger) { double("logger") }
  let(:config) { {} }

  [LogStash::Inputs::Base, LogStash::Filters::Base, LogStash::Outputs::Base].each do |plugin_base|

    subject(:plugin) do
      Class.new(plugin_base,) do
        config_name "dummy"
      end.new(config)
    end

    it "should respond to slow_logger" do
      expect(plugin.respond_to?(:slow_logger=)).to eq(true)
      expect(plugin.respond_to?(:slow_logger)).to  eq(true)
    end

    describe "notify slow operations" do

      let(:slow_logger) { double("slow_logger") }

      before(:each) do
        allow(slow_logger).to receive(:log)
        plugin.slow_logger = slow_logger
      end

      context "when the threshold is not defined" do
        it "should not report" do
          expect(slow_logger).not_to receive(:log)
          plugin.slow_logger("not.defined.op", 9)
        end
      end

      context "when the threshold is defined" do

        before(:each) do
          expect(plugin).to receive(:setting).with("your.op").and_return(15)
        end

        it "should not report to the logger if not overcome" do
          expect(slow_logger).not_to receive(:log)
          plugin.slow_logger("your.op", 14)
        end

        it "should report to the logger if overcome" do
          expect(slow_logger).to receive(:log)
          plugin.slow_logger("your.op", 16)
        end
      end
    end

    describe LogStash::Plugin::Timer do

      it "should respond to timer" do
        expect(plugin.respond_to?(:timer)).to eq(true)
      end

      it "should enable timinig operations" do
        plugin.timer.start
        sleep 0.1
        expect(plugin.timer.stop).to be > 0
      end
    end

  end

  describe LogStash::Logging::SlowLogger do

    subject { described_class.new }

    it "should respond to log" do
      expect(subject.respond_to?(:log)).to eq(true)
    end

  end
end
