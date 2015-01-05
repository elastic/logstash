# encoding: utf-8

require "spec_helper"
require "logstash/util/charset"

describe LogStash::Util::Charset do

  let(:logger)   { double("logger") }
  let(:encoding) { "UTF-8" }
  let(:charset)  { LogStash::Util::Charset.new(encoding) }
  let(:data)    { "" }

  subject { charset.convert(data) }

  context "with valid UTF-8 source encoding" do

    context "when using regular characters" do

      let(:data) { "foobar" }

      it "returns the encoded data" do eq(data) end

      it "returns the encoding name used" do
        expect(subject.encoding.name).to eq("UTF-8")
      end
    end

    context "when using non common characters" do

      let(:data) { "κόσμε" }

      it "returns the encoded data" do eq(data) end

      it "returns the encoding name used" do
        expect(subject.encoding.name).to eq("UTF-8")
      end
    end

  end

  context "with invalid UTF-8 source encoding" do

    let(:charset) do
      LogStash::Util::Charset.new(encoding).tap do |object|
        object.logger = logger
      end
    end

    context "when the invalid value is long" do

      let(:data) { "foo \xED\xB9\x81\xC3" }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("UTF-8")
      end

      it "return invalid encoding" do
        expect(data.valid_encoding?).to eq(false)
      end

      it "scapes invalid sequence" do eq("foo") end

      it "return the converted encoding name" do
        expect(logger).to receive(:warn)
        expect(subject.encoding.name).to eq("UTF-8")
      end
    end

    context "when the invalid value is short" do

      let(:data) { "bar \xAD" }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("UTF-8")
      end

      it "return invalid encoding" do
        expect(data.valid_encoding?).to eq(false)
      end

      it "scapes invalid sequence" do eq("foo") end

      it "return the converted encoding name" do
        expect(logger).to receive(:warn)
        expect(subject.encoding.name).to eq("UTF-8")
      end

    end

  end

  context "with a valid non UTF-8 encoding" do

    let(:encoding) { "ISO-8859-1" }

    context "when using regular characters" do

      let(:original) { "foobar" }
      let(:data)     { original.force_encoding(encoding) }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("ISO-8859-1")
      end

      it "return a valid encoding" do
        expect(data.valid_encoding?).to eq(true)
      end

      it "return the converted value encoding name as UTF-8" do
        expect(subject.encoding.name).to eq("UTF-8")
      end

      it "converts without any loss" do eq(original) end

    end

    context "when using extended characters" do

      let(:original) {  "à Montréal" }
      let(:data)     { "\xE0 Montr\xE9al".force_encoding(encoding) }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("ISO-8859-1")
      end

      it "return a valid encoding" do
        expect(data.valid_encoding?).to eq(true)
      end

      it "return the converted value encoding name as UTF-8" do
        expect(subject.encoding.name).to eq("UTF-8")
      end

      it "converts without any loss" do eq(original) end

    end
  end

  context "with an invalid non UTF-8 encoding" do

    let(:encoding) { "ASCII-8BIT" }

    context "when using some regular characters" do

      let(:original) { "� Montr�al" }
      let(:data)     { "\xE0 Montr\xE9al".force_encoding(encoding) }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("ASCII-8BIT")
      end

      it "return the converted value encoding name as UTF-8" do
        expect(subject.encoding.name).to eq("UTF-8")
      end

      it "converts without any loss" do eq(original) end

    end

    context "when using extended characters" do

      let(:original) {  "����������" }
      let(:data)     { "\xCE\xBA\xCF\x8C\xCF\x83\xCE\xBC\xCE\xB5".force_encoding(encoding) }

      it "return the encoding name" do
        expect(data.encoding.name).to eq("ASCII-8BIT")
      end

      it "return the converted value encoding name as UTF-8" do
        expect(subject.encoding.name).to eq("UTF-8")
      end

      it "converts without any loss" do eq(original) end

    end
  end
end
