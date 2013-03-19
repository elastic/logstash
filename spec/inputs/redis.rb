require "test_utils"
require "redis"

describe "inputs/redis" do
  extend LogStash::RSpec

  populate = proc do |key, event_count|
    require "logstash/event"
    redis = Redis.new(:host => "localhost")
    event_count.times do |value|
      event = LogStash::Event.new("@fields" => { "sequence" => value })
      Stud::try(10.times) do
        redis.rpush(key, event.to_json)
      end
    end
  end

  process = proc do |plugins, event_count|
    sequence = 0
    redis = plugins.first
    output = Shiftback.new do |event|
      insist { event["sequence"] } == sequence
      sequence += 1
      redis.teardown if sequence == event_count
    end
    redis.register
    redis.run(output)
  end # process

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

    before(:each) { populate(key, event_count) }
    input { |plugins| process(plugins, event_count) }
  end

  describe "read events from a list with batch_count=5" do
    key = 10.times.collect { rand(10).to_s }.join("")
    event_count = 1000 + rand(50)
    config <<-CONFIG
      input {
        redis {
          type => "blah"
          key => "#{key}"
          data_type => "list"
          batch_count => 5
          format => json_event
        }
      }
    CONFIG

    before(:each) { populate(key, event_count) }
    input { |plugins| process(plugins, event_count) }
  end
end
