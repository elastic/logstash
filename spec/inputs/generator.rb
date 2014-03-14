require "test_utils"

describe "inputs/generator", :performance => true do
  extend LogStash::RSpec

  describe "generate events" do
    event_count = 100000 + rand(50000)

    config <<-CONFIG
      input {
        generator {
          type => "blah"
          count => #{event_count}
        }
      }
    CONFIG

    input do |pipeline, queue|
      start = Time.now
      Thread.new { pipeline.run }
      event_count.times do |i|
        event = queue.pop
        insist { event["sequence"] } == i
      end
      duration = Time.now - start
      puts "Generator Rate: #{"%02.0f/sec" % (event_count / duration)}, Elapsed: #{duration}s"
      pipeline.shutdown
    end # input
  end
end
