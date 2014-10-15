require "logstash/codecs/json_lines"
require "logstash/event"
require "logstash/json"
require "insist"

describe LogStash::Codecs::JSONLines do
  subject do
    next LogStash::Codecs::JSONLines.new
  end

  context "#decode" do
    it "should return an event from json data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      subject.decode(LogStash::Json.dump(data) + "\n") do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
      end
    end

    it "should return an event from json data when a newline is recieved" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      subject.decode(LogStash::Json.dump(data)) do |event|
        insist {false}
      end
      subject.decode("\n") do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
      end
    end

    context "processing plain text" do
      it "falls back to plain text" do
        decoded = false
        subject.decode("something that isn't json\n") do |event|
          decoded = true
          insist { event.is_a?(LogStash::Event) }
          insist { event["message"] } == "something that isn't json"
        end
        insist { decoded } == true
      end
    end

    context "processing weird binary blobs" do
      it "falls back to plain text and doesn't crash (LOGSTASH-1595)" do
        decoded = false
        blob = (128..255).to_a.pack("C*").force_encoding("ASCII-8BIT")
        subject.decode(blob)
        subject.decode("\n") do |event|
          decoded = true
          insist { event.is_a?(LogStash::Event) }
          insist { event["message"].encoding.to_s } == "UTF-8"
        end
        insist { decoded } == true
      end
    end
  end

  context "#encode" do
    it "should return json data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { d } == "#{LogStash::Event.new(data).to_json}\n"
        insist { LogStash::Json.load(d)["foo"] } == data["foo"]
        insist { LogStash::Json.load(d)["baz"] } == data["baz"]
        insist { LogStash::Json.load(d)["bah"] } == data["bah"]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
