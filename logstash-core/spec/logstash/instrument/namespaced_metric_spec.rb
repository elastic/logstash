# encoding: utf-8
require "logstash/instrument/namespaced_metric"
require "logstash/instrument/metric"
require_relative "../../support/matchers"
require "spec_helper"

describe LogStash::Instrument::NamespacedMetric do
  let(:namespace) { :stats }

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::Metric)
  end
end
