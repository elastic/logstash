# encoding: utf-8
require "logstash/instrument/collector"
require_relative "../../support/matchers"
require "spec_helper"

describe LogStash::Instrument::Metric do
  let(:collector) { [] }
  let(:namespace) { :root }

  subject { LogStash::Instrument::Metric.new(collector) }

  context "#increment" do
    it "a counter by 1" do
      metric = subject.increment(:root, :error_rate)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 1)
    end

    it "a counter by a provided value" do
      metric = subject.increment(:root, :error_rate, 20)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.increment(:root, "", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.increment(:root, nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#decrement" do
    it "a counter by 1" do
      metric = subject.decrement(:root, :error_rate)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :decrement, 1)
    end

    it "a counter by a provided value" do
      metric = subject.decrement(:root, :error_rate, 20)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :decrement, 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.decrement(:root, "", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.decrement(:root, nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#gauge" do
    it "set the value of a key" do
      metric = subject.gauge(:root, :size_queue, 20)
      expect(collector).to be_a_metric_event([:root, :size_queue], :gauge, :set, 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.gauge(:root, "", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.gauge(:root, nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#time" do
    let(:sleep_time) { 2 }
    let(:sleep_time_ms) { sleep_time * 1_000 }

    it "records the duration" do
      subject.time(:root, :duration_ms) { sleep(sleep_time) }

      expect(collector.last).to be_within(sleep_time_ms).of(sleep_time_ms + 5)
      expect(collector[0]).to match(:root)
      expect(collector[1]).to be(:duration_ms)
      expect(collector[2]).to be(:counter)
    end

    it "returns the value of the executed block" do
      expect(subject.time(:root, :testing) { "hello" }).to eq("hello")
    end

    it "return a TimedExecution" do
      execution = subject.time(:root, :duration_ms)
      sleep(sleep_time)
      execution_time = execution.stop

      expect(execution_time).to eq(collector.last)
      expect(collector.last).to be_within(sleep_time_ms).of(sleep_time_ms + 0.1)
      expect(collector[0]).to match(:root)
      expect(collector[1]).to be(:duration_ms)
      expect(collector[2]).to be(:counter)
    end
  end

  context "#namespace" do
    let(:sub_key) { :my_sub_key }

    it "creates a new metric object and append the `sub_key` to the `base_key`" do
      expect(subject.namespace(sub_key).namespace_name).to eq([sub_key])
    end

    it "uses the same collector as the creator class" do
      child = subject.namespace(sub_key)
      metric = child.increment(:error_rate)
      expect(collector).to be_a_metric_event([sub_key, :error_rate], :counter, :increment, 1)
    end
  end
end
