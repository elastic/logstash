# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::String do
  let(:possible_values) { ["a", "b", "c"] }
  subject { described_class.new("mytext", possible_values.first, true, possible_values) }
  describe "#set" do
    context "when a value is given outside of possible_values" do
      it "should raise an ArgumentError" do
        expect { subject.set("d") }.to raise_error(ArgumentError)
      end
    end
    context "when a value is given within possible_values" do
      it "should set the value" do
        expect { subject.set("a") }.to_not raise_error
        expect(subject.value).to eq("a")
      end
    end
  end
end
