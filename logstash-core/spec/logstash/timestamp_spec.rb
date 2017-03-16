# encoding: utf-8

require "spec_helper"
require "logstash/timestamp"

describe LogStash::Timestamp do
  context "constructors" do
    it "should work" do
      t = LogStash::Timestamp.new
      expect(t.time.to_i).to be_within(1).of Time.now.to_i

      t = LogStash::Timestamp.now
      expect(t.time.to_i).to be_within(1).of Time.now.to_i

      now = Time.now.utc
      t = LogStash::Timestamp.new(now)
      expect(t.time).to eq(now)

      t = LogStash::Timestamp.at(now.to_i)
      expect(t.time.to_i).to eq(now.to_i)
    end

    it "should raise exception on invalid format" do
      expect{LogStash::Timestamp.new("foobar")}.to raise_error
    end

  end

end
