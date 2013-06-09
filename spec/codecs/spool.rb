require "logstash/codecs/spool"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Spool do
  subject do
    next LogStash::Codecs::Spool.new
  end

  context "#decode" do
    it "should return multiple spooled events" do
      e1 = LogStash::Event.new
      e2 = LogStash::Event.new
      e3 = LogStash::Event.new
      subject.decode([e1,e2,e3]) do |event|
        insist { event.is_a? LogStash::Event }
      end
    end
  end

  context "#encode" do
    it "should return a spooled event" do
      spool_size = Random.rand(10)
      subject.spool_size = spool_size
      got_event = false
      subject.on_event do |data|
        got_event = true
      end
      spool_size.times do
        subject.encode(LogStash::Event.new)
      end
      insist { got_event }
    end
  end
end
