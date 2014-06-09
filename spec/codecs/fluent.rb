# encoding: utf-8
require "logstash/codecs/fluent"
require "logstash/event"
require "insist"
require "msgpack"

describe LogStash::Codecs::Fluent do
  subject do
    next LogStash::Codecs::Fluent.new
  end

  context "#decode" do
    it "should decode packed forward" do
      data = MessagePack.pack([
        "syslog",
        MessagePack.pack([0, {"message" => "Hello World"}]).force_encoding("UTF-8") +
        MessagePack.pack([1, {"message" => "Bye World"}]).force_encoding("UTF-8")
      ])

      events = []
      subject.decode(data) do |event|
        events << event
      end

      insist { events.length } == 2

      insist { events[0].is_a? LogStash::Event }
      insist { events[0]["@timestamp"] } == Time.at(0).utc
      insist { events[0]["message"] } == "Hello World"
      insist { events[0]["tags"] } == ["syslog"]

      insist { events[1].is_a? LogStash::Event }
      insist { events[1]["@timestamp"] } == Time.at(1).utc
      insist { events[1]["message"] } == "Bye World"
      insist { events[1]["tags"] } == ["syslog"]
    end

    it "should prevent duplicate tags" do
      data = MessagePack.pack([
        "syslog",
        MessagePack.pack([0, {"message" => "Hello World", "tags" => ["syslog", "fluent"]}]).force_encoding("UTF-8")
      ])

      subject.decode(data) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["@timestamp"] } == Time.at(0).utc
        insist { event["message"] } == "Hello World"
        insist { event["tags"] } == ["syslog", "fluent"]
      end
    end

    it "should use @timestamp from data" do
      data = MessagePack.pack([
        "syslog",
        MessagePack.pack([0, {"message" => "Hello World", "@timestamp" => "2014-01-01T00:00:0.000Z"}]).force_encoding("UTF-8")
      ])

      subject.decode(data) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["@timestamp"] } == LogStash::Time.parse_iso8601("2014-01-01T00:00:0.000Z")
        insist { event["message"] } == "Hello World"
        insist { event["tags"] } == ["syslog"]
      end
    end

    it "should decode forward" do
      data = MessagePack.pack([
        "syslog",
        [[0, {"message" => "Hello World"}], [1, {"message" => "Bye World"}]]
      ])

      events = []
      subject.decode(data) do |event|
        events << event
      end

      insist { events.length } == 2

      insist { events[0].is_a? LogStash::Event }
      insist { events[0]["@timestamp"] } == Time.at(0).utc
      insist { events[0]["message"] } == "Hello World"
      insist { events[0]["tags"] } == ["syslog"]

      insist { events[1].is_a? LogStash::Event }
      insist { events[1]["@timestamp"] } == Time.at(1).utc
      insist { events[1]["message"] } == "Bye World"
      insist { events[1]["tags"] } == ["syslog"]
    end

    it "should decode message" do
      data = MessagePack.pack(["syslog", 0, {"message" => "Hello World"}])

      subject.decode(data) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["@timestamp"] } == Time.at(0).utc
        insist { event["message"] } == "Hello World"
        insist { event["tags"] } == ["syslog"]
      end
    end

    it "should ignore default tag" do
      data = MessagePack.pack(["syslog", 0, {"message" => "Hello World"}])
      subject.instance_eval {
        @ignore_tag = true
      }
      subject.decode(data) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["@timestamp"] } == Time.at(0).utc
        insist { event["message"] } == "Hello World"
        insist { event["tags"] } == nil
      end
    end
  end

  context "#encode" do
    it "should encode message" do
      event = LogStash::Event.new({"message" => "Hello World", "tags" => ["syslog"]})
      got_event = false
      subject.on_event do |data|
        insist { MessagePack.unpack(data) } == ["syslog", event["@timestamp"].to_i, {
            "message" => "Hello World",
            "tags" => ["syslog"],
            "@timestamp" => event["@timestamp"].iso8601(3),
            "@version" => event["@version"]
        }]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end

    it "should use the first tag" do
      event = LogStash::Event.new({"message" => "Hello World", "tags" => ["syslog", "fluent"]})
      got_event = false
      subject.on_event do |data|
        insist { MessagePack.unpack(data) } == ["syslog", event["@timestamp"].to_i, {
            "message" => "Hello World",
            "tags" => ["syslog", "fluent"],
            "@timestamp" => event["@timestamp"].iso8601(3),
            "@version" => event["@version"]
        }]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end

    it "should use the default tag" do
      event = LogStash::Event.new({"message" => "Hello World"})
      got_event = false
      subject.on_event do |data|
        insist { MessagePack.unpack(data) } == ["log", event["@timestamp"].to_i, {
            "message" => "Hello World",
            "@timestamp" => event["@timestamp"].iso8601(3),
            "@version" => event["@version"]
        }]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
