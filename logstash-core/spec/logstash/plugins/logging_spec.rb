# encoding: utf-8
require "spec_helper"
require "logstash/plugin"
require "logstash/outputs/base"
require "logstash/codecs/base"
require "logstash/inputs/base"
require "logstash/filters/base"
require "logstash/logging"

describe LogStash::Logging::Util::FreqItems do

  subject { described_class.new }

  it "should be possible to add an item" do
    subject.add("foo.bar.zet")
    expect(subject.size).to eq(1)
  end

  it "should return the top K items in order" do
    10.times { subject.add("foo.bar.zet") }
    5.times { subject.add("x.y.z") }
    15.times { subject.add("a.b.c") }

    expect(subject.top_k(2).map { |e| e[0] }).to eq(["a.b.c", "foo.bar.zet"])
  end
end
