# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::Integer do
  subject { described_class.new("a number", nil, false) }
  describe "#set" do
    context "when giving a number which is not an integer" do
      it "should raise an exception" do
        expect { subject.set(1.1) }.to raise_error(ArgumentError)
      end
    end
    context "when giving a number which is an integer" do
      it "should set the number" do
        expect { subject.set(100) }.to_not raise_error
        expect(subject.value).to eq(100)
      end
    end
  end
end
