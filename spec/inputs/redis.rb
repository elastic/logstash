require "test_utils"
require "redis"

describe "inputs/redis" do
  extend LogStash::RSpec

  describe "read events from a list" do
    key = 10.times.collect { rand(10).to_s }.join("")
    event_count = 1000 + rand(50)

    config <<-CONFIG
      input {
        redis {
          type => "blah"
          key => "#{key}"
          data_type => "list"
          format => json_event
        }
      }
    CONFIG

    # populate the redis list
    before :each do
      require "logstash/event"
      redis = Redis.new(:host => "localhost")
      event_count.times do |value|
        event = LogStash::Event.new("@fields" => { "sequence" => value })
        Stud::try(10.times) do
          redis.rpush(key, event.to_json)
        end
      end
    end

    input do |plugins|
      sequence = 0
      redis = plugins.first
      output = Shiftback.new do |event|
        insist { event["sequence"] } == sequence
        sequence += 1
        redis.teardown if sequence == event_count
      end
      redis.register
      redis.run(output)
    end # input
  end
end
