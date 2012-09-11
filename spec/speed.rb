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

  agent do
    puts "Rate: #{count / @duration}"
  end
end
