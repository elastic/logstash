# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::Numeric do
  subject { described_class.new("a number", nil, false) }
  describe "#set" do
    context "when giving a string which doesn't represent a string" do
      it "should raise an exception" do
        expect { subject.set("not-a-number") }.to raise_error(ArgumentError)
      end
    end
    context "when giving a string which represents a " do
      context "float" do
        it "should coerce that string to the number" do
          subject.set("1.1")
          expect(subject.value).to eq(1.1)
        end
      end
      context "int" do
        it "should coerce that string to the number" do
          subject.set("1")
          expect(subject.value).to eq(1)
        end
      end
    end
  end
end
