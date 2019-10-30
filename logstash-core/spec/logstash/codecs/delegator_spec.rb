# encoding: utf-8
require "spec_helper"

class LogStash::Codecs::MockCodec < LogStash::Codecs::Base
  config_name "my_name"

  def multi_encode(e)
  end

  def encode(e)
  end

  def decode(e)
    for i in e.split('|')
      yield i
    end
  end
end

describe LogStash::Codecs::Delegator do
  let(:collector)   { LogStash::Instrument::Collector.new }
  let(:metric) { LogStash::Instrument::Metric.new(collector) }
  let(:codec) { LogStash::Codecs::MockCodec.new }

  subject do
    delegator = described_class.new(codec, "MockCodec")
    delegator.metric = metric.namespace([:stats, :pipelines, :main, :plugins, :codecs, :my_id])
    delegator
  end

  let(:snapshot_store) { collector.snapshot_metric.metric_store }

  let(:snapshot_metric) { snapshot_store.get_shallow(:stats) }

  describe "#encode" do
    it "should delegate call to codec" do
      expect(codec).to receive(:encode).with("abcdef")
      subject.encode("abcdef")
    end

    it "should increment metrics" do
      subject.encode("test")
      expect(snapshot_metric[:pipelines][:main][:plugins][:codecs][:my_id][:encode][:writes_in].value).to eq(1)
    end
  end

  describe "#multi_encode" do
    it "should delegate call to codec" do
      expect(codec).to receive(:multi_encode).with(%w(ay laa))
      subject.multi_encode(%w(ay laa))
    end

    it "should increment metrics" do
      subject.multi_encode(%w(ay test))
      expect(snapshot_metric[:pipelines][:main][:plugins][:codecs][:my_id][:encode][:writes_in].value).to eq(2)
    end
  end

  describe "#decode" do
    it "should delegate call to codec" do
      expect(codec).to receive(:decode).with("ayooooo")
      subject.decode("ayooooo")
    end

    it "should increment metrics" do
      subject.decode("bird|law") {}
      expect(snapshot_metric[:pipelines][:main][:plugins][:codecs][:my_id][:decode][:writes_in].value).to eq(1)
      expect(snapshot_metric[:pipelines][:main][:plugins][:codecs][:my_id][:decode][:out].value).to eq(2)
    end
  end

  describe "#close" do
    it "should delegate call to codec" do
      expect(codec).to receive(:close)
      subject.close
    end
  end

  describe "#plugin_type" do
    it "should delegate call to codec" do
      expect(codec).to receive(:plugin_type)
      subject.plugin_type
    end
  end
end