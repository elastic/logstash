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
end
