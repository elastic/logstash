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

end
