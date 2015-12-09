# encoding: utf-8

require "spec_helper"
require "logstash/util"
require "logstash/event"
require "json"

TIMESTAMP = "@timestamp"

describe LogStash::Event do
  context "to_json" do
    it "should serialize simple values" do
      e = LogStash::Event.new({"foo" => "bar", "bar" => 1, "baz" => 1.0, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":\"bar\",\"bar\":1,\"baz\":1.0,\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep hash values" do
      e = LogStash::Event.new({"foo" => {"bar" => 1, "baz" => 1.0, "biz" => "boz"}, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":{\"bar\":1,\"baz\":1.0,\"biz\":\"boz\"},\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep array values" do
      e = LogStash::Event.new({"foo" => ["bar", 1, 1.0], TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"foo\":[\"bar\",1,1.0],\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\"}"))
    end

    it "should serialize deep hash from field reference assignments" do
      e = LogStash::Event.new({TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      e["foo"] = "bar"
      e["bar"] = 1
      e["baz"] = 1.0
      e["[fancy][pants][socks]"] = "shoes"
      expect(JSON.parse(e.to_json)).to eq(JSON.parse("{\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"@version\":\"1\",\"foo\":\"bar\",\"bar\":1,\"baz\":1.0,\"fancy\":{\"pants\":{\"socks\":\"shoes\"}}}"))
    end
  end

  context "[]" do
    it "should get simple values" do
      e = LogStash::Event.new({"foo" => "bar", "bar" => 1, "baz" => 1.0, TIMESTAMP => "2015-05-28T23:02:05.350Z"})
      expect(e["foo"]).to eq("bar")
      expect(e["[foo]"]).to eq("bar")
      expect(e["bar"]).to eq(1)
      expect(e["[bar]"]).to eq(1)
      expect(e["baz"]).to eq(1.0)
      expect(e["[baz]"]).to eq(1.0)
      expect(e[TIMESTAMP].to_s).to eq("2015-05-28T23:02:05.350Z")
      expect(e["[#{TIMESTAMP}]"].to_s).to eq("2015-05-28T23:02:05.350Z")
    end

    it "should get deep hash values" do
      e = LogStash::Event.new({"foo" => {"bar" => 1, "baz" => 1.0}})
      expect(e["[foo][bar]"]).to eq(1)
      expect(e["[foo][baz]"]).to eq(1.0)
    end

    it "should get deep array values" do
      e = LogStash::Event.new({"foo" => ["bar", 1, 1.0]})
      expect(e["[foo][0]"]).to eq("bar")
      expect(e["[foo][1]"]).to eq(1)
      expect(e["[foo][2]"]).to eq(1.0)
      expect(e["[foo][3]"]).to be_nil
    end
  end

  context "[]=" do
    it "should set simple values" do
      e = LogStash::Event.new()
      expect(e["foo"] = "bar").to eq("bar")
      expect(e["foo"]).to eq("bar")

      e = LogStash::Event.new({"foo" => "test"})
      expect(e["foo"] = "bar").to eq("bar")
      expect(e["foo"]).to eq("bar")
    end

    it "should set deep hash values" do
      e = LogStash::Event.new()
      expect(e["[foo][bar]"] = "baz").to eq("baz")
      expect(e["[foo][bar]"]).to eq("baz")
      expect(e["[foo][baz]"]).to be_nil
    end

    it "should set deep array values" do
      e = LogStash::Event.new()
      expect(e["[foo][0]"] = "bar").to eq("bar")
      expect(e["[foo][0]"]).to eq("bar")
      expect(e["[foo][1]"] = 1).to eq(1)
      expect(e["[foo][1]"]).to eq(1)
      expect(e["[foo][2]"] = 1.0 ).to eq(1.0)
      expect(e["[foo][2]"]).to eq(1.0)
      expect(e["[foo][3]"]).to be_nil
    end
  end

  context "timestamp" do
    it "getters should present a Ruby LogStash::Timestamp" do
      e = LogStash::Event.new()
      expect(e.timestamp.class).to eq(LogStash::Timestamp)
      expect(e[TIMESTAMP].class).to eq(LogStash::Timestamp)
    end

    it "to_hash should inject a Ruby LogStash::Timestamp" do
      e = LogStash::Event.new()

      expect(e.to_java).to be_kind_of(Java::ComLogstash::Event)
      expect(e.to_java.get_field(TIMESTAMP)).to be_kind_of(Java::ComLogstash::Timestamp)

      expect(e.to_hash[TIMESTAMP]).to be_kind_of(LogStash::Timestamp)
      # now make sure the original map was not touched
      expect(e.to_java.get_field(TIMESTAMP)).to be_kind_of(Java::ComLogstash::Timestamp)
    end

    it "should set timestamp" do
      e = LogStash::Event.new
      now = Time.now
      e["@timestamp"] = LogStash::Timestamp.at(now.to_i)
      expect(e.timestamp.to_i).to eq(now.to_i)
      expect(e["@timestamp"].to_i).to eq(now.to_i)
    end
  end

  context "append" do
    it "should append" do
      event = LogStash::Event.new("message" => "hello world")
      event.append(LogStash::Event.new("message" => "another thing"))
      expect(event["message"]).to eq(["hello world", "another thing"])
    end
  end

  context "tags" do
    it "should tag" do
      event = LogStash::Event.new("message" => "hello world")
      expect(event["tags"]).to be_nil
      event["tags"] = ["foo"]
      expect(event["tags"]).to eq(["foo"])
    end
  end


  # noop logger used to test the injectable logger in Event
  # this implementation is not complete because only the warn
  # method is used in Event.
  module DummyLogger
    def self.warn(message)
      # do nothing
    end
  end

  context "logger" do

    let(:logger) { double("Logger") }
    after(:each) {  LogStash::Event.logger = LogStash::Event::DEFAULT_LOGGER }

    # the following 2 specs are using both a real module (DummyLogger)
    # and a mock. both tests are needed to make sure the implementation
    # supports both types of objects.

    it "should set logger using a module" do
      LogStash::Event.logger = DummyLogger
      expect(DummyLogger).to receive(:warn).once
      LogStash::Event.new(TIMESTAMP => "invalid timestamp")
    end

    it "should set logger using a mock" do
      LogStash::Event.logger = logger
      expect(logger).to receive(:warn).once
      LogStash::Event.new(TIMESTAMP => "invalid timestamp")
    end

    it "should unset logger" do
      # first set
      LogStash::Event.logger = logger
      expect(logger).to receive(:warn).once
      LogStash::Event.new(TIMESTAMP => "invalid timestamp")

      # then unset
      LogStash::Event.logger = LogStash::Event::DEFAULT_LOGGER
      expect(logger).to receive(:warn).never
      # this will produce a log line in stdout by the Java Event
      LogStash::Event.new(TIMESTAMP => "ignore this log")
    end


    it "should warn on parsing error" do
      LogStash::Event.logger = logger
      expect(logger).to receive(:warn).once.with(/^Error parsing/)
      LogStash::Event.new(TIMESTAMP => "invalid timestamp")
    end

    it "should warn on invalid timestamp object" do
      LogStash::Event.logger = logger
      expect(logger).to receive(:warn).once.with(/^Unrecognized/)
      LogStash::Event.new(TIMESTAMP => Object.new)
    end
  end
end
