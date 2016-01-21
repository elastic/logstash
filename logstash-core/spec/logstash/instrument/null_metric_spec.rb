# encoding: utf-8
require "logstash/instrument/null_metric"
require "logstash/instrument/namespaced_metric"
require_relative "../../support/matchers"

describe LogStash::Instrument::NullMetric do
  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::NamespacedMetric)
  end

  describe "#time" do
    it "returns the value of the block without recording any metrics" do
      expect(subject.time(:execution_time) { "hello" }).to eq("hello")
    end

    it "return a TimedExecution" do
      execution = subject.time(:do_something)
      expect { execution.stop }.not_to raise_error
    end
  end
end
