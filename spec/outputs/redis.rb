require "test_utils"
require "logstash/outputs/redis"
require "redis"

describe LogStash::Outputs::Redis do
  extend LogStash::RSpec

  describe "ship lots of events to a list" do
    key = 10.times.collect { rand(10).to_s }.join("")
    event_count = 10000 + rand(500)

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        redis {
          host => "127.0.0.1"
          key => "#{key}"
          data_type => list
        }
      }
    CONFIG

    agent do
      # Query redis directly and inspect the goodness.
      redis = Redis.new(:host => "127.0.0.1")

      # The list should contain the number of elements our agent pushed up.
      insist { redis.llen(key) } == event_count

      # Now check all events for order and correctness.
      event_count.times do |value|
        id, element = redis.blpop(key, 0)
        event = LogStash::Event.new(JSON.parse(element))
        insist { event["sequence"] } == value
        insist { event.message } == "hello world"
        insist { event.type } == "generator"
      end

      # The list should now be empty
      insist { redis.llen(key) } == 0
    end # agent
  end

  describe "skips a message which can't be encoded as json" do
    key = 10.times.collect { rand(10).to_s }.join("")

    config <<-CONFIG
      input {
        generator {
          message => "\xAD\u0000"
          count => 1
          type => "generator"
        }
      }
      output {
        redis {
          host => "127.0.0.1"
          key => "#{key}"
          data_type => list
        }
      }
    CONFIG

    agent do
      # Query redis directly and inspect the goodness.
      redis = Redis.new(:host => "127.0.0.1")

      # The list should contain no elements.
      insist { redis.llen(key) } == 0
    end # agent
  end

  describe "converts US-ASCII to utf-8 without failures" do
    key = 10.times.collect { rand(10).to_s }.join("")

    config <<-CONFIG
      input {
        generator {
          charset => "US-ASCII"
          message => "\xAD\u0000"
          count => 1
          type => "generator"
        }
      }
      output {
        redis {
          host => "127.0.0.1"
          key => "#{key}"
          data_type => list
        }
      }
    CONFIG

    agent do
      # Query redis directly and inspect the goodness.
      redis = Redis.new(:host => "127.0.0.1")

      # The list should contain no elements.
      insist { redis.llen(key) } == 1
    end # agent
  end
end

