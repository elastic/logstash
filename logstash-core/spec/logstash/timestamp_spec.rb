# encoding: utf-8

require "spec_helper"
require "logstash/timestamp"

describe LogStash::Timestamp do
  context "constructors" do
    # Via JRuby 9k time see logstash/issues/7463
    # JRuby 9k now uses Java 8 Time with nanosecond precision but
    # our Timestamp use Joda with millisecond precision
    # expected: 2017-06-15 10:34:08.389999999 +0000
    #      got: 2017-06-15 10:34:08.389000000 +0000
    # we may need to use `be_within(0.000999999).of()` in other places too
    it "should work" do
      t = LogStash::Timestamp.new
      expect(t.time.to_i).to be_within(2).of Time.now.to_i

      t = LogStash::Timestamp.now
      expect(t.time.to_i).to be_within(2).of Time.now.to_i

      now = DateTime.now.to_time.utc
      t = LogStash::Timestamp.new(now)
      expect(t.time.to_f).to be_within(0.000999999).of(now.to_f)

      t = LogStash::Timestamp.at(now.to_i)
      expect(t.time.to_i).to eq(now.to_i)
    end

    it "should have consistent behaviour across == and .eql?" do
      its_xmas = Time.utc(2015, 12, 25, 0, 0, 0)
      expect(LogStash::Timestamp.new(its_xmas)).to eql(LogStash::Timestamp.new(its_xmas))
      expect(LogStash::Timestamp.new(its_xmas)).to be ==(LogStash::Timestamp.new(its_xmas))
    end

    it "should raise exception on invalid format" do
      expect{LogStash::Timestamp.new("foobar")}.to raise_error
    end

    it "compares to any type" do
      t = LogStash::Timestamp.new
      expect(t == '-').to be_falsey
    end

  end

end
