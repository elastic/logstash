# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::TimeValue do
  subject { described_class.new("option", "-1") }
  describe "#set" do
    it "should coerce the default correctly" do
      expect(subject.value).to eq(LogStash::Util::TimeValue.new(-1, :nanosecond).to_nanos)
    end

    context "when a value is given outside of possible_values" do
      it "should raise an ArgumentError" do
        expect { subject.set("invalid") }.to raise_error(ArgumentError)
      end
    end
    context "when a value is given as a time value" do
      it "should set the value" do
        subject.set("18m")
        expect(subject.value).to eq(LogStash::Util::TimeValue.new(18, :minute).to_nanos)
      end
    end

    context "when a value is given as a nanosecond" do
      it "should set the value" do
        subject.set(5)
        expect(subject.value).to eq(LogStash::Util::TimeValue.new(5, :nanosecond).to_nanos)
      end
    end
  end
end
