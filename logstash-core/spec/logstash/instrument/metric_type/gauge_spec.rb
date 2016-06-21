# encoding: utf-8
require "logstash/instrument/metric_type/gauge"
require "logstash/json"
require "spec_helper"

describe LogStash::Instrument::MetricType::Gauge do
  let(:namespaces) { [:root, :pipelines, :pipeline_01] }
  let(:key) { :mykey }
  let(:value) { "hello" }

  subject { described_class.new(namespaces, key) }

  before :each do
    subject.execute(:set, value)
  end

  describe "#execute" do
    it "set the value of the gauge" do
      expect(subject.value).to eq(value)
    end
  end

  context "When serializing to JSON" do
    it "serializes the value" do
      expect(LogStash::Json.dump(subject)).to eq("\"#{value}\"")
    end
  end

  context "When creating a hash " do
    it "creates the hash from all the values" do
      metric_hash = {
        key => value
      }
      expect(subject.to_hash).to match(metric_hash)
    end
  end
end
