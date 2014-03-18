# encoding: utf-8

require "logstash/codecs/plain"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Plain do
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

    it "should respect the format setting" do
      format = "%{[hello]} %{[something][fancy]}"
      codec = LogStash::Codecs::Plain.new("format" => format)
      event = LogStash::Event.new("hello" => "world", "something" => { "fancy" => 123 })
      codec.on_event do |data|
        insist { data } == event.sprintf(format)
      end
      codec.encode(event)
    end

  end
end
