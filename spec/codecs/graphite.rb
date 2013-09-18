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
    
    it "should return multiple events given multiple graphite formated lines" do
      total_count = Random.rand(20)
      names = Array.new(total_count) { Random.srand.to_s(36) }
      values = Array.new(total_count) { Random.rand*1000 }
      timestamps = Array.new(total_count) { Time.now.gmtime.to_i }
      data = Array.new(total_count) {|i| "#{names[i]} #{values[i]} #{timestamps[i]}\n"}
      counter = 0
      subject.decode(data.join('')) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event[names[counter]] } == values[counter]
        counter = counter+1
      end
      insist { counter } == total_count
    end
    
    it "should not return an event until newline is hit" do
      name = Random.srand.to_s(36)
      value = Random.rand*1000
      timestamp = Time.now.gmtime.to_i
      event_returned = false
      subject.decode("#{name} #{value} #{timestamp}") do |event|
        event_returned = true
      end
      insist { !event_returned }
      subject.decode("\n") do |event|
        insist { event.is_a? LogStash::Event }
        insist { event[name] } == value
        event_returned = true
      end
      insist { event_returned }
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
      subject.encode(LogStash::Event.new("@timestamp" => timestamp))
    end
    
    it "should treat fields as metrics if fields as metrics flag is set" do
      name = Random.srand.to_s(36)
      value = Random.rand*1000
      timestamp = Time.now.gmtime.to_i
      subject.fields_are_metrics = true
      subject.on_event do |event|
        insist { event.is_a? String }
        insist { event } == "#{name} #{value} #{timestamp.to_i}\n"
      end
      subject.encode(LogStash::Event.new({name => value, "@timestamp" => timestamp}))
      
      #even if metrics param is set
      subject.metrics = {"foo" => 4}
      subject.encode(LogStash::Event.new({name => value, "@timestamp" => timestamp}))
    end
    
    it "should change the metric name format when metrics_format is set" do
      name = Random.srand.to_s(36)
      value = Random.rand*1000
      timestamp = Time.now.gmtime
      subject.metrics = {name => value}
      subject.metrics_format = "foo.bar.*.baz"
      subject.on_event do |event|
        insist { event.is_a? String }
        insist { event } == "foo.bar.#{name}.baz #{value} #{timestamp.to_i}\n"
      end
      subject.encode(LogStash::Event.new("@timestamp" => timestamp))
    end
  end
end
