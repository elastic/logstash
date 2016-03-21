# encoding: utf-8
require "spec_helper"
require "logstash/timestamp"
require "bigdecimal"

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

  context "identity methods" do
    subject { LogStash::Timestamp.new }

    it "should support utc" do
      expect(subject.utc).to eq(subject)
    end

    it "should support gmtime" do
      expect(subject.gmtime).to eq(subject)
    end
  end

  context "numeric casting methods" do
    let (:now) {Time.now}
    subject { LogStash::Timestamp.new(now) }

    it "should support to_i" do
      expect(subject.to_i).to eq(now.to_i)
    end

    it "should support to_f" do
      expect(subject.to_f).to eq(now.to_f)
    end
  end

  context "at" do
    context "with integer epoch" do
      it "should convert to correct date" do
        expect(LogStash::Timestamp.at(946702800).to_iso8601).to eq("2000-01-01T05:00:00.000Z")
      end

      it "should return zero usec" do
        expect(LogStash::Timestamp.at(946702800).usec).to eq(0)
      end

      it "should return prior to epoch date on negative input" do
        expect(LogStash::Timestamp.at(-1).to_iso8601).to eq("1969-12-31T23:59:59.000Z")
      end
    end

    context "with float epoch" do
      it "should convert to correct date" do
        expect(LogStash::Timestamp.at(946702800.123456.to_f).to_iso8601).to eq("2000-01-01T05:00:00.123Z")
      end

      it "should return usec with a minimum of millisec precision" do
        expect(LogStash::Timestamp.at(946702800.123456.to_f).usec).to be_within(1000).of(123456)
      end
    end

    context "with BigDecimal epoch" do
      it "should convert to correct date" do
        expect(LogStash::Timestamp.at(BigDecimal.new("946702800.123456")).to_iso8601).to eq("2000-01-01T05:00:00.123Z")
      end

      it "should return usec with a minimum of millisec precision" do
        # since Java Timestamp relies on JodaTime which supports only milliseconds precision
        # the usec method will only be precise up to milliseconds.
        expect(LogStash::Timestamp.at(BigDecimal.new("946702800.123456")).usec).to be_within(1000).of(123456)
      end
    end

    context "with illegal parameters" do
      it "should raise exception on nil input" do
        expect{LogStash::Timestamp.at(nil)}.to raise_error
      end

      it "should raise exception on invalid input type" do
        expect{LogStash::Timestamp.at(:foo)}.to raise_error
      end
    end
  end

  context "usec" do
    it "should support millisecond precision" do
      expect(LogStash::Timestamp.at(946702800.123).usec).to eq(123000)
    end

    it "should try to preserve and report microseconds precision if possible" do
      # since Java Timestamp relies on JodaTime which supports only milliseconds precision
      # the usec method will only be precise up to milliseconds.
      expect(LogStash::Timestamp.at(946702800.123456).usec).to be_within(1000).of(123456)
    end
  end
end
