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

  context "When serializing to JSON" do
    it "serializes the value" do
      expect(LogStash::Json.dump(subject)).to eq("0")
    end
  end

end
