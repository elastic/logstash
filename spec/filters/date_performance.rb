require "test_utils"
require "logstash/filters/date"

puts "Skipping date tests because this ruby is not jruby" if RUBY_ENGINE != "jruby"
RUBY_ENGINE == "jruby" and describe LogStash::Filters::Date do
  extend LogStash::RSpec

  describe "performance test of java syntax parsing" do

    event_count = 100000
    min_rate = 4000

    max_duration = event_count / min_rate
    input = "Nov 24 01:29:01 -0800"
    config <<-CONFIG
      input {
        generator {
          add_field => ["mydate", "#{input}"]
          count => #{event_count}
          type => "generator"
        }
      }
      filter {
        date {
          match => [ "mydate", "MMM dd HH:mm:ss Z" ]
        }
      }
      output { null { } }
    CONFIG

    2.times do
      agent do
        puts "date parse rate: #{event_count / @duration}"
        insist { @duration } < max_duration
      end
    end
  end
end
