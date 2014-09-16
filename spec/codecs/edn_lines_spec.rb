require "logstash/codecs/edn_lines"
require "logstash/event"
require "logstash/json"
require "insist"
require "edn"

describe LogStash::Codecs::EDNLines do
  subject do
    next LogStash::Codecs::EDNLines.new
  end

  context "#decode" do
    it "should return an event from edn data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a", "b", "c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      subject.decode(data.to_edn + "\n") do |event|
        insist { event }.is_a?(LogStash::Event)
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
        insist { event["@timestamp"].to_iso8601 } == data["@timestamp"]
      end
    end

    it "should return an event from edn data when a newline is recieved" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      subject.decode(data.to_edn) do |event|
        insist {false}
      end
      subject.decode("\n") do |event|
        insist { event.is_a? LogStash::Event }
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
        insist { EDN.read(d)["@timestamp"] } == event["@timestamp"].to_iso8601
       got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end

    it "should return edn data rom deserialized json with normalization" do
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
