# encoding: utf-8

require "test_utils"
require "logstash/util/charset"

describe LogStash::Util::Charset do
  let(:logger) { double("logger") }

  context "with valid UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("UTF-8")}

    it "should return untouched data" do
      ["foobar", "κόσμε"].each do |data|
        insist { data.encoding.name } == "UTF-8"
        insist { subject.convert(data) } == data
        insist { subject.convert(data).encoding.name } == "UTF-8"
      end
    end
  end

  context "with invalid UTF-8 source encoding" do
    subject do
      LogStash::Util::Charset.new("UTF-8").tap do |charset|
        charset.logger = logger
      end
    end

    it "should escape invalid sequences" do
      ["foo \xED\xB9\x81\xC3", "bar \xAD"].each do |data|
        insist { data.encoding.name } == "UTF-8"
        insist { data.valid_encoding? } == false
        logger.should_receive(:warn).twice
        insist { subject.convert(data) } == data.inspect[1..-2]
        insist { subject.convert(data).encoding.name } == "UTF-8"
      end
    end

  end

  context "with valid non UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("ISO-8859-1")}

    it "should encode to UTF-8" do
      samples = [
        ["foobar", "foobar"],
        ["\xE0 Montr\xE9al", "à Montréal"],
      ]
      samples.map{|(a, b)| [a.force_encoding("ISO-8859-1"), b]}.each do |(a, b)|
        insist { a.encoding.name } == "ISO-8859-1"
        insist { b.encoding.name } == "UTF-8"
        insist { a.valid_encoding? } == true
        insist { subject.convert(a).encoding.name } == "UTF-8"
        insist { subject.convert(a) } == b
      end
    end
  end

  context "with invalid non UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("ASCII-8BIT")}

    it "should encode to UTF-8 and replace invalid chars" do
      samples = [
        ["\xE0 Montr\xE9al", "� Montr�al"],
        ["\xCE\xBA\xCF\x8C\xCF\x83\xCE\xBC\xCE\xB5", "����������"],
      ]
      samples.map{|(a, b)| [a.force_encoding("ASCII-8BIT"), b]}.each do |(a, b)|
        insist { a.encoding.name } == "ASCII-8BIT"
        insist { b.encoding.name } == "UTF-8"
        insist { subject.convert(a).encoding.name } == "UTF-8"
        insist { subject.convert(a) } == b
      end
    end
  end
end
