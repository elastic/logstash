# encoding: utf-8

require "spec_helper"
require "logstash/util/unicode_trimmer"
require "flores/rspec"
require "flores/random"

RSpec.configure do |config|
  Flores::RSpec.configure(config)
end

describe "truncating unicode strings correctly" do
  subject { LogStash::Util::UnicodeTrimmer }

  context "with extra bytes before the snip" do
    let(:ustr) { "Testing «ταБЬℓσ»: 1<2 & 4+1>3, now 20% off!" }

    it "should truncate to exact byte boundaries when possible" do
      expect(subject.trim_bytes(ustr, 21).bytesize).to eql(21)
    end

    it "should truncate below the bytesize when splitting a byte" do
      expect(subject.trim_bytes(ustr, 20).bytesize).to eql(18)
    end

    it "should not truncate the string when the bytesize is already OK" do
      expect(subject.trim_bytes(ustr, ustr.bytesize)).to eql(ustr)
    end
  end

  context "with extra bytes after the snip" do
    let(:ustr) { ": 1<2 & 4+1>3, now 20% off! testing «ταБЬℓσ»" }

    it "should truncate to exact byte boundaries when possible" do
      expect(subject.trim_bytes(ustr, 21).bytesize).to eql(21)
    end

    it "should truncate below the bytesize when splitting a byte" do
      expect(subject.trim_bytes(ustr, 52).bytesize).to eql(51)
    end

    it "should not truncate the string when the bytesize is already OK" do
      expect(subject.trim_bytes(ustr, ustr.bytesize)).to eql(ustr)
    end
  end

  context "randomized testing" do
    let(:text) { Flores::Random.text(1..1000) }
    let(:size) { Flores::Random.integer(1..text.bytesize) }
    let(:expected_range) { (size - 4)..size }

    stress_it "should be near the boundary of requested size" do
      expect(expected_range).to include(subject.trim_bytes(text, size).bytesize)
    end
  end
end
