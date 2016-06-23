# encoding: utf-8
require "logstash/instrument/null_metric"
require "logstash/instrument/namespaced_metric"
require_relative "../../support/shared_examples"

describe LogStash::Instrument::NullMetric do
  # This is defined in the `namespaced_metric_spec`
  include_examples "metrics commons operations"

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::NamespacedMetric)
  end

  describe "#namespace" do
    it "return a NullMetric" do
      expect(subject.namespace(key)).to be_kind_of LogStash::Instrument::NullMetric
    end
  end
end
