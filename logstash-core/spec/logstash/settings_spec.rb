# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting do
  let(:logger) { double("logger") }
  describe "#value" do
    context "when using a default value" do
      context "when no value is set" do
        subject { described_class.new("number", Numeric, 1) }
        it "should return the default value" do
          expect(subject.value).to eq(1)
        end
      end

      context "when a value is set" do
        subject { described_class.new("number", Numeric, 1) }
        let(:new_value) { 2 }
        before :each do
          subject.set(new_value)
        end
        it "should return the set value" do
          expect(subject.value).to eq(new_value)
        end
      end
    end

    context "when not using a default value" do
      context "when no value is set" do
        subject { described_class.new("number", Numeric, nil, false) }
        it "should return the default value" do
          expect(subject.value).to eq(nil)
        end
      end

      context "when a value is set" do
        subject { described_class.new("number", Numeric, nil, false) }
        let(:new_value) { 2 }
        before :each do
          subject.set(new_value)
        end
        it "should return the set value" do
          expect(subject.value).to eq(new_value)
        end
      end
    end
  end

  describe "#set?" do
    context "when there is not value set" do
      subject { described_class.new("number", Numeric, 1) }
      it "should return false" do
        expect(subject.set?).to be(false)
      end
    end
    context "when there is a value set" do
      subject { described_class.new("number", Numeric, 1) }
      before :each do
        subject.set(2)
      end
      it "should return false" do
        expect(subject.set?).to be(true)
      end
    end
  end
  describe "#set" do
    subject { described_class.new("number", Numeric, 1) }
    it "should change the value of a setting" do
      expect(subject.value).to eq(1)
      subject.set(4)
      expect(subject.value).to eq(4)
    end
    context "when executed for the first time" do
      it "should change the result of set?" do
        expect(subject.set?).to eq(false)
        subject.set(4)
        expect(subject.set?).to eq(true)
      end
    end

    context "when the argument's class does not match @klass" do
      it "should throw an exception" do
        expect { subject.set("not a number") }.to raise_error
      end
    end
  end
end
