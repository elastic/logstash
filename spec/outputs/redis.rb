require "test_utils"
require "logstash/outputs/redis"
require "redis"

describe LogStash::Outputs::Redis do
  extend LogStash::RSpec

  around :each do |example|
    service = File.join(File.dirname(__FILE__), "../../test/services/redis")
    system("make -C '#{service}' build")
    redis = Dir.glob(File.join(service, "redis*/src/redis-server")).first
    puts "STARTING REDIS"
    redis_proc = IO.popen("cd '#{service}'; exec '#{redis}' 2>&1", "r")
    Thread.new do
      redis_proc.each do |line|
        puts "redis[#{redis_proc.pid}]: #{line.chomp}"
      end
    end

    example.run

    Process.kill("KILL", redis_proc.pid)
    Process.wait(redis_proc.pid)
  end

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
end

