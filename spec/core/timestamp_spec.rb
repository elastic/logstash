require "spec_helper"
require "logstash/timestamp"

describe LogStash::Timestamp do

  let(:t)  { Time.now }
  let(:ts) { LogStash::Timestamp.new(t) }

  it "parse its own iso8601 output" do
    timestamp = LogStash::Timestamp.parse_iso8601(ts.to_iso8601)
    expect(timestamp.to_i).to eq(t.to_i)
  end

  context "coerce" do

    it "iso8601 string" do
      timestamp = LogStash::Timestamp.coerce(ts.to_iso8601)
      expect(timestamp.to_i).to eq(t.to_i)
    end

    it "Time" do
      timestamp = LogStash::Timestamp.coerce(t)
      expect(timestamp.to_i).to eq(t.to_i)
    end

    it "Timestamp" do
      now = LogStash::Timestamp.now
      timestamp = LogStash::Timestamp.coerce(now)
      expect(timestamp.to_i).to eq(now.to_i)
    end

    context "with invalid data" do
      it "raise on invalid string" do
        expect{LogStash::Timestamp.coerce("foobar")}.to raise_error LogStash::TimestampParserError
      end

      it "return nil on invalid object" do
        expect(LogStash::Timestamp.coerce(:foobar)).to be_nil
      end
    end
  end

  context "to_json" do

    it "transform data without errors" do
      timestamp = LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00-0800")
      expect(timestamp.to_json).to eq("\"2014-09-23T08:00:00.000Z\"")
    end

    it "can use ignore arguments" do
      timestamp = LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00-0800")
      expect(timestamp.to_json(:some => 1, :argumnents => "test")).to eq("\"2014-09-23T08:00:00.000Z\"")
    end
  end

  context "comparison" do

    let(:current) { LogStash::Timestamp.new(Time.now)  }
    let(:future) { LogStash::Timestamp.new(Time.now + 100) }

    it "support the gt operator" do
      expect(future > current).to eq(true)
    end
    it "support the lt operator" do
      expect(future < current).to eq(false)
    end
    it "support the eq operator" do
      expect(current == current).to eq(true)
    end
    it "support the comparison operator with equal pairs" do
      expect(current <=> current).to eq(0)
    end
    it "support the comparison operator with lt pairs" do
      expect(current <=> future).to eq(-1)
    end
    it "support the comparison operator with gt pairs" do
      expect(future <=> current).to eq(1)
    end
  end

  context "operators" do

    let(:now) { Time.now }

    context "addition" do
      it "allow unary operation +" do
        timestamp = LogStash::Timestamp.new(now) + 10
        expect(timestamp).to eq(now + 10)
      end
    end

    context "subtraction" do

      it "work on a timestamp object" do
        current = LogStash::Timestamp.new(now)
        future = LogStash::Timestamp.new(now + 10)
        expect(future - current).to eq(10)
      end

      it "work on with time object" do
        t = LogStash::Timestamp.new(now + 10)
        expect(t - now).to eq(10)
      end

      it "work with numeric value" do
        timestamp = LogStash::Timestamp.new(now + 10)
        expect(timestamp - 10).to eq(now)
      end
    end
  end
end
