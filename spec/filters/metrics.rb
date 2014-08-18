require "logstash/filters/metrics"

describe LogStash::Filters::Metrics do

  context "with basic meter config" do
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
        subject {
          config = {"meter" => ["http.%{response}"]}
          filter = LogStash::Filters::Metrics.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 404})
          filter.flush
        }

        it "should flush counts" do
          insist { subject.length } == 1
          insist { subject.first["http.200.count"] } == 2
          insist { subject.first["http.404.count"] } == 1
        end

        it "should include rates and percentiles" do
          metrics = ["http.200.rate_1m", "http.200.rate_5m", "http.200.rate_15m",
                     "http.404.rate_1m", "http.404.rate_5m", "http.404.rate_15m"]
          metrics.each do |metric|
            insist { subject.first }.include? metric
          end
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

    context "when custom rates and percentiles are selected" do
      context "on the first flush" do
        subject {
          config = {
            "meter" => ["http.%{response}"],
            "rates" => [1]
          }
          filter = LogStash::Filters::Metrics.new config
          filter.register
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 200})
          filter.filter LogStash::Event.new({"response" => 404})
          filter.flush
        }

        it "should include only the requested rates" do
          rate_fields = subject.first.to_hash.keys.select {|field| field.start_with?("http.200.rate") }
          insist { rate_fields.length } == 1
          insist { rate_fields }.include? "http.200.rate_1m"
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

  context "with timer config" do
    context "on the first flush" do
      subject {
        config = {"timer" => ["http.request_time", "%{request_time}"]}
        filter = LogStash::Filters::Metrics.new config
        filter.register
        filter.filter LogStash::Event.new({"request_time" => 10})
        filter.filter LogStash::Event.new({"request_time" => 20})
        filter.filter LogStash::Event.new({"request_time" => 30})
        filter.flush
      }

      it "should flush counts" do
        insist { subject.length } == 1
        insist { subject.first["http.request_time.count"] } == 3
      end

      it "should include rates and percentiles keys" do
        metrics = ["rate_1m", "rate_5m", "rate_15m", "p1", "p5", "p10", "p90", "p95", "p99"]
        metrics.each do |metric|
          insist { subject.first }.include? "http.request_time.#{metric}"
        end
      end

      it "should include min value" do
        insist { subject.first['http.request_time.min'] } == 10.0
      end

      it "should include mean value" do
        insist { subject.first['http.request_time.mean'] } == 20.0
      end

      it "should include stddev value" do
        insist { subject.first['http.request_time.stddev'] } == Math.sqrt(10.0)
      end

      it "should include max value" do
        insist { subject.first['http.request_time.max'] } == 30.0
      end

      it "should include percentile value" do
        insist { subject.first['http.request_time.p99'] } == 30.0
      end
    end
  end

  context "when custom rates and percentiles are selected" do
    context "on the first flush" do
      subject {
        config = {
          "timer" => ["http.request_time", "request_time"],
          "rates" => [1],
          "percentiles" => [1, 2]
        }
        filter = LogStash::Filters::Metrics.new config
        filter.register
        filter.filter LogStash::Event.new({"request_time" => 1})
        filter.flush
      }

      it "should flush counts" do
        insist { subject.length } == 1
        insist { subject.first["http.request_time.count"] } == 1
      end

      it "should include only the requested rates" do
        rate_fields = subject.first.to_hash.keys.select {|field| field.start_with?("http.request_time.rate") }
        insist { rate_fields.length } == 1
        insist { rate_fields }.include? "http.request_time.rate_1m"
      end

      it "should include only the requested percentiles" do
        percentile_fields = subject.first.to_hash.keys.select {|field| field.start_with?("http.request_time.p") }
        insist { percentile_fields.length } == 2
        insist { percentile_fields }.include? "http.request_time.p1"
        insist { percentile_fields }.include? "http.request_time.p2"
      end
    end
  end


  context "when a custom flush_interval is set" do
    it "should flush only when required" do
      config = {"meter" => ["http.%{response}"], "flush_interval" => 15}
      filter = LogStash::Filters::Metrics.new config
      filter.register
      filter.filter LogStash::Event.new({"response" => 200})

      insist { filter.flush }.nil?        # 5s
      insist { filter.flush }.nil?        # 10s
      insist { filter.flush.length } == 1 # 15s
      insist { filter.flush }.nil?        # 20s
      insist { filter.flush }.nil?        # 25s
      insist { filter.flush.length } == 1 # 30s
    end
  end

  context "when a custom clear_interval is set" do
    it "should clear the metrics after interval has passed" do
      config = {"meter" => ["http.%{response}"], "clear_interval" => 15}
      filter = LogStash::Filters::Metrics.new config
      filter.register
      filter.filter LogStash::Event.new({"response" => 200})

      insist { filter.flush.first["http.200.count"] } == 1 # 5s
      insist { filter.flush.first["http.200.count"] } == 1 # 10s
      insist { filter.flush.first["http.200.count"] } == 1 # 15s
      insist { filter.flush }.nil?                         # 20s
    end
  end

  context "when invalid rates are set" do
    subject {
      config = {"meter" => ["http.%{response}"], "rates" => [90]}
      filter = LogStash::Filters::Metrics.new config
    }

    it "should raise an error" do
      insist {subject.register }.raises(LogStash::ConfigurationError)
    end
  end
end
