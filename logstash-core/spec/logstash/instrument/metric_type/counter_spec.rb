# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "spec_helper"

describe LogStash::Instrument::MetricType::Counter do
  let(:namespaces) { [:root, :pipelines, :pipeline_01] }
  let(:key) { :mykey }

  subject { LogStash::Instrument::MetricType::Counter.new(namespaces, key) }

  describe "#increment" do
    it "increment the counter" do
      expect{ subject.increment }.to change { subject.value }.by(1)
    end
  end

  describe "#decrement" do
    it "decrement the counter" do
      expect{ subject.decrement }.to change { subject.value }.by(-1)
    end
  end

  describe "#to_hash" do
    it "return the details of the counter" do
      expect(subject.to_hash).to include({ "namespaces" => namespaces,
                                           "key" => key,
                                           "value" => 0,
                                           "type" => "counter" })
    end
  end
end
