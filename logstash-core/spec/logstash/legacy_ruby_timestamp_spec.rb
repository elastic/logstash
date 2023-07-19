# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"
require "bigdecimal"

describe LogStash::Timestamp do
  # Via JRuby 9k time see logstash/issues/7463
  # JRuby 9k now uses Java 8 Time with nanosecond precision but
  # our Timestamp use Joda with millisecond precision
  #        expected: 10
  #             got: 9.999000001
  # we may need to use `be_within(0.000999999).of()` in other places too
  it "should parse its own iso8601 output" do
    t = Time.now
    ts = LogStash::Timestamp.new(t)
    parsed = LogStash::Timestamp.parse_iso8601(ts.to_iso8601)
    expect(parsed.to_i).to eq(t.to_i)
    expect(parsed).to eq(ts)
  end

  it "should coerce iso8601 string" do
    t = DateTime.now.to_time
    ts = LogStash::Timestamp.new(t)
    coerced = LogStash::Timestamp.coerce(ts.to_iso8601)
    expect(coerced.to_i).to eq(t.to_i)
    expect(coerced).to eq(ts)
  end

  it "should coerce Time" do
    t = Time.now
    coerced = LogStash::Timestamp.coerce(t)
    expect(coerced.to_i).to eq(t.to_i)
    expect(coerced.time).to eq(t)
  end

  it "should coerce Timestamp" do
    t = LogStash::Timestamp.now
    coerced = LogStash::Timestamp.coerce(t)
    expect(coerced.to_i).to eq(t.to_i)
    expect(coerced).to eq(t)
  end

  it "should raise on invalid string coerce" do
    expect {LogStash::Timestamp.coerce("foobar")}.to raise_error LogStash::TimestampParserError
  end

  it "should return nil on invalid object coerce" do
    expect(LogStash::Timestamp.coerce(:foobar)).to be_nil
  end

  context '#to_json' do
    it "should support to_json" do
      expect(LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00.123-0800").to_json).to eq("\"2014-09-23T08:00:00.123Z\"")
    end

    it "should support to_json and ignore arguments" do
      expect(LogStash::Timestamp.parse_iso8601("2014-09-23T00:00:00.456-0800").to_json(:some => 1, :arguments => "test")).to eq("\"2014-09-23T08:00:00.456Z\"")
    end

    context 'variable serialization length' do
      subject(:timestamp) { LogStash::Timestamp.parse_iso8601(time_string) }
      context 'with whole seconds' do
        let(:time_string) { "2014-09-23T00:00:00.000-0800" }
        it 'serializes a 24-byte string' do
          expect(timestamp.to_json).to eq('"2014-09-23T08:00:00.000Z"')
        end
      end
      context 'with excess millis' do
        let(:time_string) { "2014-09-23T00:00:00.123000-0800" }
        it 'serializes a 24-byte string' do
          expect(timestamp.to_json).to eq('"2014-09-23T08:00:00.123Z"')
        end
      end
      context 'with excess micros' do
        let(:time_string) { "2014-09-23T00:00:00.000100-0800" }
        it 'serializes a 27-byte string' do
          expect(timestamp.to_json).to eq('"2014-09-23T08:00:00.000100Z"')
        end
      end
      context 'with excess nanos' do
        let(:time_string) { "2014-09-23T00:00:00.000000010-0800" }
        it 'serializes a 30-byte string' do
          expect(timestamp.to_json).to eq('"2014-09-23T08:00:00.000000010Z"')
        end
      end
    end
  end

  it "should support timestamp comparison" do
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
    current = DateTime.now.to_time
    t = LogStash::Timestamp.new(current) + 10
    expect(t).to be_within(0.000999999).of(current + 10)
  end

  describe "subtraction" do
    it "should work on a timestamp object" do
      t = DateTime.now.to_time
      current = LogStash::Timestamp.new(t)
      future = LogStash::Timestamp.new(t + 10)
      expect(future - current).to be_within(0.000999999).of(10)
    end

    it "should work on with time object" do
      current = DateTime.now.to_time
      t = LogStash::Timestamp.new(current + 10)
      expect(t - current).to be_within(0.000999999).of(10)
    end

    it "should work with numeric value" do
      current = DateTime.now.to_time
      t = LogStash::Timestamp.new(current + 10)
      expect(t - 10).to be_within(0.000999999).of(current)
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
    let(:now) { Time.now }
    subject { LogStash::Timestamp.new(now) }

    it "should support to_i" do
      expect(subject.to_i).to be_kind_of(Integer)
    end

    it "should support to_f" do
      expect(subject.to_f).to be_kind_of(Float)
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
        expect(LogStash::Timestamp.at(946702800.123456).to_f).to be_within(0.000001).of(946702800.123456)
      end

      it "should return usec with a minimum of millisec precision" do
        expect(LogStash::Timestamp.at(946702800.123456789.to_f).usec).to be_within(1000).of(123456)
      end
    end

    context "with BigDecimal epoch" do
      it "should convert to correct date" do
        expect(LogStash::Timestamp.at(BigDecimal("946702800.123456789")).to_iso8601).to eq("2000-01-01T05:00:00.123456789Z")
      end

      it "should return usec with a minimum of millisec precision" do
        expect(LogStash::Timestamp.at(BigDecimal("946702800.123456789")).usec).to be_within(1000).of(123456)
      end
    end

    context "with illegal parameters" do
      it "should raise exception on nil input" do
        expect {LogStash::Timestamp.at(nil)}.to raise_error
      end

      it "should raise exception on invalid input type" do
        expect {LogStash::Timestamp.at(:foo)}.to raise_error
      end
    end
  end

  context "usec" do
    it "should support millisecond precision" do
      expect(LogStash::Timestamp.at(946702800.123).usec).to eq(123000)
    end

    it "preserves microseconds precision if possible" do
      expect(LogStash::Timestamp.at(946702800.123456).usec).to eq(123456)
    end

    it "truncates excess nanos" do
      expect(LogStash::Timestamp.at(946702800.123456789).usec).to eq(123456)
    end
  end

  context "nsec" do
    # iterate through a list of known edge-cases, plus one random.
    # if we get a test failure and identify a regression, add its value to the list.
    [
      000000000,
      499999999,
      500000000,
      999999999,
      Random.rand(1_000_000_000)
    ].each do |excess_nanos|
      context "with excess_nanos=`#{'%09d' % excess_nanos}`" do
        let(:epoch_seconds) { Time.now.to_i }
        let(:excess_nanos) {  }

        let(:rational_time) { epoch_seconds + Rational(excess_nanos, 1_000_000_000) }

        subject(:timestamp) { LogStash::Timestamp.at(rational_time) }

        it "supports nanosecond precision" do
          expect(timestamp.nsec).to eq(excess_nanos)
        end
      end
    end
  end
end
