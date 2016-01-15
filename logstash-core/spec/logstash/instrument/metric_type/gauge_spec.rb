# encoding: utf-8
require "logstash/instrument/metric_type/gauge"
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

  describe "#to_hash" do

    it "return the details of the gauge" do
      expect(subject.to_hash).to include({ "namespaces" => namespaces,
                                           "key" => key,
                                           "value" => value,
                                           "type" => "gauge" })
    end
  end
end
