# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::CloudId do
  subject { described_class.new("mycloudid", nil) }

  describe "#set" do
    context "when given a string which is not a cloud id" do
      it "should raise an exception" do
        expect { subject.set("foobarbaz") }.to raise_error(ArgumentError, /Cloud Id does not decode/)
      end
    end

    context "when given a string which is empty" do
      it "should raise an exception" do
        expect { subject.set("") }.to raise_error(ArgumentError, /Cloud Id does not decode/)
      end
    end

    context "when given a string which is has environment prefix only" do
      it "should raise an exception" do
        expect { subject.set("testing:") }.to raise_error(ArgumentError, /Cloud Id does not decode/)
      end
    end

    context "when given a nil" do
      it "should not raise an error" do
        expect { subject.set(nil) }.to_not raise_error
      end
    end

    context "when given a string which is an unlabelled cloud id" do
      it "should set a LogStash::Util::CloudId instance" do
        expect { subject.set("dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy") }.to_not raise_error
        expect(subject.value.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
        expect(subject.value.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
        expect(subject.value.label).to eq("")
      end
    end

    context "when given a string which is a labelled cloud id" do
      it "should set a LogStash::Util::CloudId instance" do
        expect { subject.set("staging:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy") }.to_not raise_error
        expect(subject.value.elasticsearch_host).to eq("notareal.us-east-1.aws.found.io:443")
        expect(subject.value.kibana_host).to eq("identifier.us-east-1.aws.found.io:443")
        expect(subject.value.label).to eq("staging")
      end
    end
  end
end
