require "logstash/codecs/edn"
require "logstash/event"
require "insist"
require "edn"

describe LogStash::Codecs::EDN do
  subject do
    next LogStash::Codecs::EDN.new
  end

  context "#decode" do
    it "should return an event from edn data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a", "b", "c"]}}
      subject.decode(data.to_edn) do |event|
        insist { event }.is_a?(LogStash::Event)
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
      end
    end
  end

  context "#encode" do
    it "should return edn data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { d.chomp } == LogStash::Event.new(data).to_hash.to_edn
        insist { EDN.read(d)["foo"] } == data["foo"]
        insist { EDN.read(d)["baz"] } == data["baz"]
        insist { EDN.read(d)["bah"] } == data["bah"]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end

end
