require "logstash/codecs/msgpack"
require "logstash/event"
require "insist"

# Skip msgpack for now since Hash#to_msgpack seems to not be a valid method?
describe LogStash::Codecs::Msgpack, :if => false  do
  subject do
    next LogStash::Codecs::Msgpack.new
  end

  context "#decode" do
    it "should return an event from msgpack data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      subject.decode(data.to_msgpack) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["foo"] } == data["foo"]
        insist { event["baz"] } == data["baz"]
        insist { event["bah"] } == data["bah"]
      end
    end
  end

  context "#encode" do
    it "should return msgpack data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |d|
        insist { d } == LogStash::Event.new(data).to_hash.to_msgpack
        insist { MessagePack.unpack(d)["foo"] } == data["foo"]
        insist { MessagePack.unpack(d)["baz"] } == data["baz"]
        insist { MessagePack.unpack(d)["bah"] } == data["bah"]
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end
end
