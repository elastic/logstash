require "logstash/codecs/plain"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Plain do
  subject do
    next LogStash::Codecs::Plain.new
  end

  context "#decode" do
    it "should return a valid event" do
      subject.decode("Testing decoding.") do |event|
        insist { event.is_a? LogStash::Event }
      end
    end
  end

  context "#encode" do
    it "should return a plain text encoding" do
      event = LogStash::Event.new
      event["message"] = "Hello World."
      subject.on_event do |data|
        insist { data } == event.to_s
      end
      subject.encode(event)
    end
  end
end
