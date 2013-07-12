require "logstash/filters/metrics"

describe LogStash::Filters::Metrics do

  context "with basic config" do
    context "when no events were received" do
      it "should not flush" do
        config = {"meter" => ["http.%{response}"]}
        filter = LogStash::Filters::Metrics.new config
        filter.register

        events = filter.flush
        insist { events }.nil?
      end
    end

    context "when events are received" do
      context "on the first flush" do
        it "should flush counts" do
          config = {"meter" => ["http.%{response}"]}
          filter = LogStash::Filters::Metrics.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 404})

          events = filter.flush
          insist { events.length } == 1
          insist { events.first["http.200.count"] } == 2
          insist { events.first["http.404.count"] } == 1
        end
      end

      context "on the second flush" do
        it "should not reset counts" do
          config = {"meter" => ["http.%{response}"]}
          filter = LogStash::Filters::Metrics.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 404})

          events = filter.flush
          events = filter.flush
          insist { events.length } == 1
          insist { events.first["http.200.count"] } == 2
          insist { events.first["http.404.count"] } == 1
        end
      end
    end
  end

  context "with multiple instances" do
    it "counts should be independent" do
      config_tag1 = {"meter" => ["http.%{response}"], "tags" => ["tag1"]}
      config_tag2 = {"meter" => ["http.%{response}"], "tags" => ["tag2"]}
      filter_tag1 = LogStash::Filters::Metrics.new config_tag1
      filter_tag2 = LogStash::Filters::Metrics.new config_tag2
      event_tag1 = LogStash::Event.new({"response" => 200, "tags" => [ "tag1" ]})
      event_tag2 = LogStash::Event.new({"response" => 200, "tags" => [ "tag2" ]})
      event2_tag2 = LogStash::Event.new({"response" => 200, "tags" => [ "tag2" ]})
      filter_tag1.register
      filter_tag2.register

      [event_tag1, event_tag2, event2_tag2].each do |event|
        filter_tag1.filter event
        filter_tag2.filter event
      end

      events_tag1 = filter_tag1.flush
      events_tag2 = filter_tag2.flush

      insist { events_tag1.first["http.200.count"] } == 1
      insist { events_tag2.first["http.200.count"] } == 2
    end
  end
end
