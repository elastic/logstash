# encoding: utf-8

require "logstash/codecs/line"
require "logstash/event"

describe LogStash::Codecs::Line do
  subject do
    next LogStash::Codecs::Line.new
  end

  context "#encode" do
    let (:event) {LogStash::Event.new({"message" => "hello world", "host" => "test"})}

    it "should return a default date formatted line" do
      expect(subject).to receive(:on_event).once.and_call_original
      subject.on_event do |d|
        insist {d} == event.to_s + "\n"
      end
      subject.encode(event)
    end

    it "should respect the supplied format" do
      format = "%{host}"
      subject.format = format
      expect(subject).to receive(:on_event).once.and_call_original
      subject.on_event do |d|
        insist {d} == event.sprintf(format) + "\n"
      end
      subject.encode(event)
    end
  end

  context "#decode" do
    it "should return an event from an ascii string" do
      decoded = false
      subject.decode("hello world\n") do |e|
        decoded = true
        insist { e.is_a?(LogStash::Event) }
        insist { e["message"] } == "hello world"
      end
      insist { decoded } == true
    end

    it "should return an event from a valid utf-8 string" do
      subject.decode("München\n") do |e|
        insist { e.is_a?(LogStash::Event) }
        insist { e["message"] } == "München"
      end
    end
  end
end
