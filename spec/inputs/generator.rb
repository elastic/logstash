require "test_utils"

describe "inputs/generator" do
  extend LogStash::RSpec

  class Shiftcount
    def initialize; @count = 0; end
    def <<(arg); @count += 1 end
    attr_reader :count
  end

  describe "generate events" do
    event_count = 100000 + rand(50)

    config <<-CONFIG
      input {
        generator {
          type => "blah"
          count => #{event_count}
        }
      }
    CONFIG

    input do |plugins|
      sequence = 0
      generator = plugins.first
      output = Shiftcount.new
      generator.register
      start = Time.now
      generator.run(output)
      duration = Time.now - start
      puts "Rate: #{event_count / duration}"
    end # input
  end
end
