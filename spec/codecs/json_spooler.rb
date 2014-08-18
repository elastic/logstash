require "logstash/codecs/json_spooler"
require "logstash/event"
require "logstash/json"
require "insist"

describe LogStash::Codecs::JsonSpooler do
  subject do
    # mute deprecation message
    expect_any_instance_of(LogStash::Codecs::JsonSpooler).to receive(:register).and_return(nil)

    LogStash::Codecs::JsonSpooler.new
  end

  context "#decode" do
    it "should return an event from spooled json data" do
      data = {"a" => 1}
      events = [LogStash::Event.new(data), LogStash::Event.new(data),
        LogStash::Event.new(data)]
      subject.decode(LogStash::Json.dump(events)) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event["a"] } == data["a"]
      end
    end
  end

  context "#encode" do
    it "should return spooled json data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}}
      subject.spool_size = 3
      got_event = false
      subject.on_event do |d|
        events = LogStash::Json.load(d)
        insist { events.is_a? Array }
        insist { events[0].is_a? LogStash::Event }
        insist { events[0]["foo"] } == data["foo"]
        insist { events[0]["baz"] } == data["baz"]
        insist { events[0]["bah"] } == data["bah"]
        insist { events.length } == 3
        got_event = true
      end
      3.times do
        subject.encode(LogStash::Event.new(data))
      end
      insist { got_event }
    end
  end
end
