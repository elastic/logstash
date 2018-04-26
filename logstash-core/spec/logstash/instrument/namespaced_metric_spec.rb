# encoding: utf-8
require_relative "../../support/matchers"
require_relative "../../support/shared_examples"
require "spec_helper"

describe LogStash::Instrument::NamespacedMetric do
  let(:namespace) { :root }
  let(:collector) { [] }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }

  subject { described_class.new(metric, namespace) }

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::Metric)
  end

  it "returns a TimedException when we call without a block" do
    expect(subject.time(:duration_ms)).to be_kind_of(LogStash::Instrument::Metric::TimedExecution)
  end

  it "returns the value of the block" do
    expect(subject.time(:duration_ms) { "hello" }).to eq("hello")
  end

  it "its doesnt change the original `namespace` when creating a subnamespace" do
    new_namespace = subject.namespace(:wally)

    expect(subject.namespace_name).to eq([namespace])
    expect(new_namespace.namespace_name).to eq([:root, :wally])
  end

  context "#increment" do
    it "a counter by 1" do
      metric = subject.increment(:error_rate)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 1)
    end

    it "a counter by a provided value" do
      metric = subject.increment(:error_rate, 20)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 20)
    end
  end

  context "#decrement" do
    it "a counter by 1" do
      metric = subject.decrement(:error_rate)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :decrement, 1)
    end

    it "a counter by a provided value" do
      metric = subject.decrement(:error_rate, 20)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :decrement, 20)
    end
  end

  context "#gauge" do
    it "set the value of a key" do
      metric = subject.gauge(:size_queue, 20)
      expect(collector).to be_a_metric_event([:root, :size_queue], :gauge, :set, 20)
    end
  end

  context "#time" do
    let(:sleep_time) { 2 }
    let(:sleep_time_ms) { sleep_time * 1_000 }

    it "records the duration" do
      subject.time(:duration_ms) { sleep(sleep_time) }

      expect(collector.last).to be_within(sleep_time_ms).of(sleep_time_ms + 5)
      expect(collector[0]).to match([:root])
      expect(collector[1]).to be(:duration_ms)
      expect(collector[2]).to be(:counter)
    end

    it "return a TimedExecution" do
      execution = subject.time(:duration_ms)
      sleep(sleep_time)
      execution_time = execution.stop

      expect(execution_time).to eq(collector.last)
      expect(collector.last).to be_within(sleep_time_ms).of(sleep_time_ms + 0.1)
      expect(collector[0]).to match([:root])
      expect(collector[1]).to be(:duration_ms)
      expect(collector[2]).to be(:counter)
    end
  end

  include_examples "metrics commons operations"
end
