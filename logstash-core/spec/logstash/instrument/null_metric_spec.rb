# encoding: utf-8
require "logstash/instrument/null_metric"
require "logstash/instrument/metric"
require_relative "../../support/matchers"

describe LogStash::Instrument::NullMetric do
  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::Metric) 
  end
end
