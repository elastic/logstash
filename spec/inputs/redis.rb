require "test_utils"
require "redis"

def populate(key, event_count)
  require "logstash/event"
  redis = Redis.new(:host => "localhost")
  event_count.times do |value|
    event = LogStash::Event.new("sequence" => value)
    Stud::try(10.times) do
      redis.rpush(key, event.to_json)
    end
  end
end

def process(pipeline, queue, event_count)
  sequence = 0
  Thread.new { pipeline.run }
  event_count.times do |i|
    event = queue.pop
    insist { event["sequence"] } == i
  end
  pipeline.shutdown
end # process

describe "inputs/redis", :redis => true do
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
        }
      }
    CONFIG

    before(:each) { populate(key, event_count) }

    input { |pipeline, queue| process(pipeline, queue, event_count) }
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
          batch_count => #{rand(20)+1}
        }
      }
    CONFIG

    before(:each) { populate(key, event_count) }
    input { |pipeline, queue| process(pipeline, queue, event_count) }
  end
end
