require "spec_helper"

describe "speed tests", :performance => true do
  
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
