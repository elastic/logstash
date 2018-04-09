# encoding: utf-8
require "spec_helper"
require "logstash/util/cloud_setting_id"

describe LogStash::Util::CloudSettingId do
  let(:input) { "foobar:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy" }
  subject { described_class.new(input) }

  describe "when given unacceptable input" do
    it "a nil input does not raise an exception" do
      expect{described_class.new(nil)}.not_to raise_exception
    end
    it "when given a nil input, the accessors are all nil" do
      cloud_id = described_class.new(nil)
      expect(cloud_id.original).to be_nil
      expect(cloud_id.decoded).to be_nil
      expect(cloud_id.label).to be_nil
      expect(cloud_id.elasticsearch_host).to be_nil
      expect(cloud_id.kibana_host).to be_nil
      expect(cloud_id.elasticsearch_scheme).to be_nil
      expect(cloud_id.kibana_scheme).to be_nil
    end

    context "when a malformed value is given" do
      let(:raw) {%w(first second)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect{subject}.to raise_exception(ArgumentError, "Cloud Id does not decode. You may need to enable Kibana in the Cloud UI. Received: \"#{raw[0]}$#{raw[1]}\".")
      end
    end

    context "when at least one segment is empty" do
      let(:raw) {["first", "", "third"]}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect{subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{raw[0]}$#{raw[1]}$#{raw[2]}\".")
      end
    end

    context "when elasticsearch segment is undefined" do
      let(:raw) {%w(us-east-1.aws.found.io undefined my-kibana)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect{subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.")
      end
    end

    context "when kibana segment is undefined" do
      let(:raw) {%w(us-east-1.aws.found.io my-elastic-cluster undefined)}
      let(:input) { described_class.cloud_id_encode(*raw) }
      it "raises an error" do
        expect{subject}.to raise_exception(ArgumentError, "Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.")
      end
    end
  end

  describe "without a label" do
    let(:input) { "dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy" }
    it "#label is empty" do
      expect(subject.label).to be_empty
    end
    it "#decode is set" do
      expect(subject.decoded).to eq("us-east-1.aws.found.io$notareal$identifier")
    end
  end

  describe "when given acceptable input, the accessors:" do
    it '#original has a value' do
      expect(subject.original).to eq(input)
    end
    it '#decoded has a value' do
      expect(subject.decoded).to eq("us-east-1.aws.found.io$notareal$identifier")
    end
    it '#label has a value' do
      expect(subject.label).to eq("foobar")
    end
    it '#elasticsearch_host has a value' do
      expect(subject.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
    end
    it '#elasticsearch_scheme has a value' do
      expect(subject.elasticsearch_scheme).to eq("https")
    end
    it '#kibana_host has a value' do
      expect(subject.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
    end
    it '#kibana_scheme has a value' do
      expect(subject.kibana_scheme).to eq("https")
    end
    it '#to_s has a value of #decoded' do
      expect(subject.to_s).to eq(subject.decoded)
    end
  end
end