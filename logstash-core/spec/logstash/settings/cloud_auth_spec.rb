# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::CloudAuth do
  subject { described_class.new("mycloudauth", nil) }

  describe "#set" do
    context "when given a string without a separator or a password" do
      it "should raise an exception" do
        expect { subject.set("foobarbaz") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string without a password" do
      it "should raise an exception" do
        expect { subject.set("foo:") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string without a username" do
      it "should raise an exception" do
        expect { subject.set(":bar") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a string which is empty" do
      it "should raise an exception" do
        expect { subject.set("") }.to raise_error(ArgumentError, /Cloud Auth username and password format should be/)
      end
    end

    context "when given a nil" do
      it "should not raise an error" do
        expect { subject.set(nil) }.to_not raise_error
      end
    end

    context "when given a string which is a cloud auth" do
      it "should set the string" do
        expect { subject.set("frodo:baggins") }.to_not raise_error
        expect(subject.value.username).to eq("frodo")
        expect(subject.value.password.value).to eq("baggins")
      end
    end
  end
end