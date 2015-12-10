# encoding: utf-8
require "logstash/instrument/metric"
require "logstash/instrument/collector"
require "spec_helper"

describe LogStash::Instrument::Metric do
  let(:collector) { [] }
  let(:namespace) { :root }

  subject { LogStash::Instrument::Metric.new(collector, namespace) }

  context "#increment" do
    it "a counter by 1" do
      metric = subject.increment(:error_rate)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 1)
    end

    it "a counter by a provided value" do
      metric = subject.increment(:error_rate, 20)
      expect(collector).to be_a_metric_event([:root, :error_rate], :counter, :increment, 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.increment("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.increment(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
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

    it "raises an exception if the key is an empty string" do
      expect { subject.decrement("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.decrement(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#gauge" do
    it "set the value of a key" do
      metric = subject.gauge(:size_queue, 20)
      expect(collector).to be_a_metric_event([:root, :size_queue], :gauge, 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.gauge("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.gauge(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#namespace" do
    let(:sub_key) { :my_sub_key }

    it "creates a new metric object and append the `sub_key` to the `base_key`" do
      expect(subject.namespace(sub_key).namespace_information).to eq([namespace, sub_key])
    end

    it "uses the same collector as the creator class" do
      child = subject.namespace(sub_key)
      expect(subject.collector).to eq(child.collector)
    end
  end
end
