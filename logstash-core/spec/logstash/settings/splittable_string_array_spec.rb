# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::SplittableStringArray do
  let(:element_class) { String }
  let(:default_value) { [] }

  subject { described_class.new("testing", element_class, default_value) }

  before do
    subject.set(candidate)
  end

  context "when giving an array" do
    let(:candidate) { ["hello,", "ninja"] }

    it "returns the same elements" do
      expect(subject.value).to match(candidate)
    end
  end

  context "when given a string" do
    context "with 1 element" do
      let(:candidate) { "hello" }

      it "returns 1 element" do
        expect(subject.value).to match(["hello"])
      end
    end

    context "with multiple element" do
      let(:candidate) { "hello,ninja" }

      it "returns an array of string" do
        expect(subject.value).to match(["hello", "ninja"])
      end
    end
  end

  context "when defining a custom tokenizer" do
    subject { described_class.new("testing", element_class, default_value, strict=true, ";") }

    let(:candidate) { "hello;ninja" }

    it "returns an array of string" do
      expect(subject.value).to match(["hello", "ninja"])
    end
  end
end

