require "logstash/codecs/json"
require "logstash/event"
require "insist"

describe LogStash::Codecs::JSON do
  subject do
    next LogStash::Codecs::JSON.new
  end

  context "#decode" do
    it "should return an event from json data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      subject.decode(data.to_json) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
      end
    end
  end

  context "#encode" do
    it "should return json data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { d.chomp } == LogStash::Event.new(data).to_json
        insist { JSON.parse(d)["foo"] } == data["foo"]
        insist { JSON.parse(d)["baz"] } == data["baz"]
        insist { JSON.parse(d)["bah"] } == data["bah"]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
