require "test_utils"
require "logstash/filters/kv"

describe LogStash::Filters::KV do
  extend LogStash::RSpec

  describe "defaults" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        kv { }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
    end

  end

  describe "speed test" do
    count = 10000 + rand(3000)
    config <<-CONFIG
      input {
        generator {
          count => #{count}
          type => foo
          message => "hello=world bar='baz fizzle'"
        }
      }

      filter {
        kv { }
      }

      output  {
        null { }
      }
    CONFIG

    agent do
      p :duration => @duration, :rate => count/@duration
    end
  end
end
