# encoding: utf-8
require "logstash/util/time_value"
require "spec_helper"

RSpec.shared_examples "coercion example" do |value, expected|
  let(:value) { value }
  let(:expected) { expected }
  it 'coerces correctly' do
    expect(LogStash::Util::TimeValue.from_value(value)).to eq(expected)
  end
end


module LogStash module Util
describe TimeValue do
    it_behaves_like "coercion example", TimeValue.new(100, :hour), TimeValue.new(100, :hour)
    it_behaves_like "coercion example", "18nanos", TimeValue.new(18, :nanosecond)
    it_behaves_like "coercion example", "18micros", TimeValue.new(18, :microsecond)
    it_behaves_like "coercion example", "18ms", TimeValue.new(18, :millisecond)
    it_behaves_like "coercion example", "18s", TimeValue.new(18, :second)
    it_behaves_like "coercion example", "18m", TimeValue.new(18, :minute)
    it_behaves_like "coercion example", "18h", TimeValue.new(18, :hour)
    it_behaves_like "coercion example", "18d", TimeValue.new(18, :day)

    it "coerces with a space between the duration and the unit" do
      expected = TimeValue.new(18, :hour)
      actual = TimeValue.from_value("18      h")
      expect(actual).to eq(expected)
    end

    it "fails to coerce non-ints" do
      begin
        a = TimeValue.from_value("f18 nanos")
        fail "should not parse"
      rescue ArgumentError => e
        expect(e.message).to eq("invalid value for Integer(): \"f18\"")
      end
    end

    it "fails to coerce invalid units" do
      begin
        a = TimeValue.from_value("18xyz")
        fail "should not parse"
      rescue ArgumentError => e
        expect(e.message).to eq("invalid time unit: \"18xyz\"")
      end
    end

    it "fails to coerce invalid value types" do
      begin
        a = TimeValue.from_value(32)
        fail "should not parse"
      rescue ArgumentError => e
        expect(e.message).to eq("value is not a string: 32 [Fixnum]")
      end
    end
end
end
end
