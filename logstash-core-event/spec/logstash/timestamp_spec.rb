# encoding: utf-8
require "spec_helper"
require "logstash/timestamp"

describe LogStash::Timestamp do

  it "should parse its own iso8601 output" do
    t = Time.now
    ts = LogStash::Timestamp.new(t)
    expect(LogStash::Timestamp.parse_iso8601(ts.to_iso8601).to_i).to eq(t.to_i)
  end

  it "should coerce iso8601 string" do
    t = Time.now
    ts = LogStash::Timestamp.new(t)
    expect(LogStash::Timestamp.coerce(ts.to_iso8601).to_i).to eq(t.to_i)
  end

  it "should coerce Time" do
    t = Time.now
    expect(LogStash::Timestamp.coerce(t).to_i).to eq(t.to_i)
  end

  it "should coerce Timestamp" do
    t = LogStash::Timestamp.now
    expect(LogStash::Timestamp.coerce(t).to_i).to eq(t.to_i)
  end

  it "should raise on invalid string coerce" do
    expect{LogStash::Timestamp.coerce("foobar")}.to raise_error LogStash::TimestampParserError
  end

  it "should return nil on invalid object coerce" do
    expect(LogStash::Timestamp.coerce(:foobar)).to be_nil
  end

  it "should support to_json" do
    expect(LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00-0800").to_json).to eq("\"2014-09-23T08:00:00.000Z\"")
  end

  it "should support to_json and ignore arguments" do
    expect(LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00-0800").to_json(:some => 1, :argumnents => "test")).to eq("\"2014-09-23T08:00:00.000Z\"")
  end

  it "should support timestamp comparaison" do
   current = LogStash::Timestamp.new(Time.now) 
   future = LogStash::Timestamp.new(Time.now + 100)

   expect(future > current).to eq(true)
   expect(future < current).to eq(false)
   expect(current == current).to eq(true)

   expect(current <=> current).to eq(0)
   expect(current <=> future).to eq(-1)
   expect(future <=> current).to eq(1)
  end

  it "should allow unary operation +" do
    current = Time.now
    t = LogStash::Timestamp.new(current) + 10
    expect(t).to eq(current + 10)
  end

  describe "subtraction" do
    it "should work on a timestamp object" do
      t = Time.now
      current = LogStash::Timestamp.new(t)
      future = LogStash::Timestamp.new(t + 10)
      expect(future - current).to eq(10)
    end

    it "should work on with time object" do
      current = Time.now
      t = LogStash::Timestamp.new(current + 10)
      expect(t - current).to eq(10)
    end

    it "should work with numeric value" do
      current = Time.now
      t = LogStash::Timestamp.new(current + 10)
      expect(t - 10).to eq(current)
    end
  end
end
