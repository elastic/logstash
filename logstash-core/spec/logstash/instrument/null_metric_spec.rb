# encoding: utf-8
require_relative "../../support/shared_examples"
require_relative "../../support/matchers"
require "spec_helper"

describe LogStash::Instrument::NullMetric do

  let(:key) { "test" }
  subject { LogStash::Instrument::NullMetric.new(nil) }

  it "defines the same interface as `Metric`" do
    expect(described_class).to implement_interface_of(LogStash::Instrument::Metric)
  end

  describe "#namespace" do
    it "return a NamespacedNullMetric" do
      expect(subject.namespace(key)).to be_kind_of LogStash::Instrument::NamespacedNullMetric
    end
  end
end
