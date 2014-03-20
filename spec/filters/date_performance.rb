require "test_utils"
require "logstash/filters/date"

puts "Skipping date tests because this ruby is not jruby" if RUBY_ENGINE != "jruby"
describe LogStash::Filters::Date, :if => RUBY_ENGINE == "jruby" do
  extend LogStash::RSpec

  describe "speed test of date parsing", :performance => true do
    it "should be fast" do
      event_count = 100000
      min_rate = 4000
      max_duration = event_count / min_rate
      input = "Nov 24 01:29:01 -0800"

      filter = LogStash::Filters::Date.new("match" => [ "mydate", "MMM dd HH:mm:ss Z" ])
      filter.register
      duration = 0
      # 10000 for warmup
      [10000, event_count].each do |iterations|
        start = Time.now
        iterations.times do
          event = LogStash::Event.new("mydate" => input)
          filter.execute(event)
        end
        duration = Time.now - start
      end
      puts "filters/date parse rate: #{"%02.0f/sec" % (event_count / duration)}, elapsed: #{duration}s"
      insist { duration } < max_duration
    end
  end
end
