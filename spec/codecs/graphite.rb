require "logstash/codecs/graphite"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Graphite do
  subject do
    next LogStash::Codecs::Graphite.new
  end

  context "#decode" do
    it "should return an event from single full graphite line" do
      name = Random.srand.to_s(36)
      value = Random.rand*1000
      timestamp = Time.now.gmtime.to_i
      subject.decode("#{name} #{value} #{timestamp}\n") do |event|
        insist { event.is_a? LogStash::Event }
        insist { event[name] } == value
      end
    end
  end
  
  context "#encode" do
    it "should emit an graphite formatted line" do
      name = Random.srand.to_s(36)
      value = Random.rand*1000
      timestamp = Time.now.gmtime
      subject.metrics = {name => value}
      subject.on_event do |event|
        insist { event.is_a? String }
        insist { event } == "#{name} #{value} #{timestamp.to_i}\n"
      end
      subject.encode(LogStash::Event.new)
    end
  end
end
