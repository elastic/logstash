# encoding: utf-8
require "spec_helper"
require "logstash/plugin"
require "logstash/outputs/base"
require "logstash/codecs/base"
require "logstash/inputs/base"
require "logstash/filters/base"
require "logstash/logging"

describe LogStash::Logging::Util::TopItems do

  subject { described_class.new }

  it "should be possible to add an item" do
    subject.add("key", 1)
    expect(subject.size).to eq(1)
  end

  it "should retrieve Top K in value order" do
    subject.add("foo.bar.zet", 10)
    subject.add("x.y.z", 5)
    subject.add("a.b.c", 15)
    expect(subject.top_k(2).map { |o| o.threshold }).to eq(["a.b.c", "foo.bar.zet"])
  end

  it "should keep only N elements in the set" do
    11.times do |i|
      subject.add("#{i}.foo.bar.#{i}", rand(20))
    end
    expect(subject.size).to eq(10)
  end
end

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
