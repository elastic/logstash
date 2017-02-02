# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::ArrayCoercible do
  subject { described_class.new("option", element_class, value) }
  let(:value) { [ ] }
  let(:element_class) { Object }

  context "when given a non array value" do
    let(:value) { "test" }
    describe "the value" do
      it "is converted to an array with that single element" do
        expect(subject.value).to eq(["test"])
      end
    end
  end

  context "when given an array value" do
    let(:value) { ["test"] }
    describe "the value" do
      it "is not modified" do
        expect(subject.value).to eq(value)
      end
    end
  end

  describe "initialization" do
    subject { described_class }
    let(:element_class) { Fixnum }
    context "when given values of incorrect element class" do
      let(:value) { "test" }

      it "will raise an exception" do
        expect { described_class.new("option", element_class, value) }.to raise_error(ArgumentError)
      end
    end
    context "when given values of correct element class" do
      let(:value) { 1 }

      it "will not raise an exception" do
        expect { described_class.new("option", element_class, value) }.not_to raise_error
      end
    end
  end
end
