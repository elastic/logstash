require "test_utils"

describe "speed tests" do
  extend LogStash::RSpec
  count = 1000000

  config <<-CONFIG
    input {
      generator {
        type => foo
        count => #{count}
      }
    }
    output { null { } }
  CONFIG

  start = Time.now
  agent do
    duration = (Time.now - start)
    puts "Speed Rate: #{"%02.0f/sec" % (count / duration)}, Elapsed: #{duration}s"
  end
end
