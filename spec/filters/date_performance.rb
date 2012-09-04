require "test_utils"
require "logstash/filters/date"

describe LogStash::Filters::Date do
  extend LogStash::RSpec

  describe "performance test of java syntax parsing" do

    event_count = 50000
    max_duration = 10
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
          mydate => "MMM dd HH:mm:ss Z"
        }
      }
    CONFIG

    agent do
        insist { @duration } < max_duration
      end
  end
end