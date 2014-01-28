require "logstash/codecs/oldlogstashjson"
require "logstash/event"
require "insist"

describe LogStash::Codecs::OldLogStashJSON do
  subject do
    next LogStash::Codecs::OldLogStashJSON.new
  end

  context "#decode" do
    it "should return a new (v1) event from old (v0) json data" do
      data = {"@message" => "bar", "@source_host" => "localhost",
              "@tags" => ["a","b","c"]}
      subject.decode(data.to_json) do |event|
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
        insist { JSON.parse(d)["@timestamp"] } != nil
        insist { JSON.parse(d)["@type"] } == data["type"]
        insist { JSON.parse(d)["@message"] } == data["message"]
        insist { JSON.parse(d)["@source_host"] } == data["host"]
        insist { JSON.parse(d)["@source_path"] } == data["path"]
        insist { JSON.parse(d)["@tags"] } == data["tags"]
        insist { JSON.parse(d)["@fields"]["bah"] } == "baz"
        insist { JSON.parse(d)["@fields"]["@version"] } == nil
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
