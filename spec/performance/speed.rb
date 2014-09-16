require "test_utils"

describe "speed tests", :performance => true do
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
    puts "speed rate: #{"%02.0f/sec" % (count / duration)}, elapsed: #{duration}s"
  end
end
