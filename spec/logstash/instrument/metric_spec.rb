# encoding: utf-8
require "logstash/instrument/metric"
require "logstash/instrument/collector"

RSpec::Matchers.define :be_a_metric_event do |type, key, value|
  match do |actual|
    actual.first == type &&
      actual[1].kind_of?(Time) &&
      actual[2] == key &&
      actual.last == value
  end
end

describe LogStash::Instrument::Metric do
  let(:collector) { [] }

  let(:base_key) { "root" }
  subject { LogStash::Instrument::Metric.new(collector, base_key) }

  context "#increment" do
    it "a counter by 1" do
      metric = subject.increment("error-rate")
      expect(collector.pop).to be_a_metric_event(:counter_increment, "root-error-rate", 1)
    end

    it "a counter by a provided value" do
      metric = subject.increment("error-rate", 20)
      expect(metric.pop).to be_a_metric_event(:counter_increment,"root-error-rate", 20)
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
      metric = subject.decrement("error-rate")
      expect(collector.pop).to be_a_metric_event(:counter_decrement, "root-error-rate", 1)
    end

    it "a counter by a provided value" do
      metric = subject.decrement("error-rate", 20)
      expect(metric.pop).to be_a_metric_event(:counter_decrement,"root-error-rate", 20)
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
      metric = subject.gauge("size-queue", 20)
      expect(metric.pop).to be_a_metric_event(:gauge,"root-size-queue", 20)
    end

    it "raises an exception if the key is an empty string" do
      expect { subject.gauge("", 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end

    it "raise an exception if the key is nil" do
      expect { subject.gauge(nil, 20) }.to raise_error(LogStash::Instrument::MetricNoKeyProvided)
    end
  end

  context "#namespace" do
    let(:sub_key) { "my-sub-key" }

    it "creates a new metric object and append the `sub_key` to the `base_key`" do
      expect(subject.namespace(sub_key).base_key).to eq([base_key, sub_key].join("-"))
    end

    it "uses the same collector as the creator class" do
      child = subject.namespace(sub_key)
      expect(subject.collector).to eq(child.collector)
    end
  end
end
