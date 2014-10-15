require "logstash/codecs/edn"
require "logstash/event"
require "logstash/json"
require "insist"
require "edn"

describe LogStash::Codecs::EDN do
  subject do
    next LogStash::Codecs::EDN.new
  end

  context "#decode" do
    it "should return an event from edn data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a", "b", "c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      subject.decode(data.to_edn) do |event|
        insist { event }.is_a?(LogStash::Event)
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
        insist { event["@timestamp"].to_iso8601 } == data["@timestamp"]
      end
    end
  end

  context "#encode" do
    it "should return edn data from pure ruby hash" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { EDN.read(d)["foo"] } == data["foo"]
        insist { EDN.read(d)["baz"] } == data["baz"]
        insist { EDN.read(d)["bah"] } == data["bah"]
        insist { EDN.read(d)["@timestamp"] } == "2014-05-30T02:52:17.929Z"
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end

    # this is to test the case where the event data has been produced by json
    # deserialization using JrJackson in :raw mode which creates Java LinkedHashMap
    # and not Ruby Hash which will not be monkey patched with the #to_edn method
    it "should return edn data from deserialized json with normalization" do
      data = LogStash::Json.load('{"foo": "bar", "baz": {"bah": ["a","b","c"]}, "@timestamp": "2014-05-30T02:52:17.929Z"}')
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { EDN.read(d)["foo"] } == data["foo"]
        insist { EDN.read(d)["baz"] } == data["baz"]
        insist { EDN.read(d)["bah"] } == data["bah"]
        insist { EDN.read(d)["@timestamp"] } == "2014-05-30T02:52:17.929Z"
        insist { EDN.read(d)["@timestamp"] } == event["@timestamp"].to_iso8601
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end

end
