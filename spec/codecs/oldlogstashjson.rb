require "logstash/codecs/oldlogstashjson"
require "logstash/event"
require "logstash/json"
require "insist"

describe LogStash::Codecs::OldLogStashJSON do
  subject do
    next LogStash::Codecs::OldLogStashJSON.new
  end

  context "#decode" do
    it "should return a new (v1) event from old (v0) json data" do
      data = {"@message" => "bar", "@source_host" => "localhost",
              "@tags" => ["a","b","c"]}
      subject.decode(LogStash::Json.dump(data)) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["@timestamp"] } != nil
        insist { event["type"] } == data["@type"]
        insist { event["message"] } == data["@message"]
        insist { event["host"] } == data["@source_host"]
        insist { event["tags"] } == data["@tags"]
        insist { event["path"] } == nil # @source_path not in v0 test data
      end
    end

    it "should accept invalid json" do
      subject.decode("some plain text") do |event|
        insist { event["message"] } == "some plain text"
      end
    end
  end

  context "#encode" do
    it "should return old (v0) json data" do
      data = {"type" => "t", "message" => "wat!?",
              "host" => "localhost", "path" => "/foo",
              "tags" => ["a","b","c"],
              "bah" => "baz"}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { LogStash::Json.load(d)["@timestamp"] } != nil
        insist { LogStash::Json.load(d)["@type"] } == data["type"]
        insist { LogStash::Json.load(d)["@message"] } == data["message"]
        insist { LogStash::Json.load(d)["@source_host"] } == data["host"]
        insist { LogStash::Json.load(d)["@source_path"] } == data["path"]
        insist { LogStash::Json.load(d)["@tags"] } == data["tags"]
        insist { LogStash::Json.load(d)["@fields"]["bah"] } == "baz"
        insist { LogStash::Json.load(d)["@fields"]["@version"] } == nil
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
