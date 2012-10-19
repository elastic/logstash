require "test_utils"
require "ftw"

describe "outputs/elasticsearch" do
  extend LogStash::RSpec

  describe "ship lots of events" do
    # Generate a random index name
    index = 10.times.collect { rand(10).to_s }.join("")

    # Write about 10000 events. Add jitter to increase likeliness of finding
    # boundary-related bugs.
    event_count = 10000 + rand(500)

    embedded_http_port = rand(20000) + 10000

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        elasticsearch {
          embedded => true
          embedded_http_port => #{embedded_http_port}
          cluster => "#{index}"
          index => "#{index}"
          index_type => "testing"
        }
      }
    CONFIG

    agent do
      # Try a few times to check if we have the correct number of events stored
      # in ES.
      #
      # We try multiple times to allow final agent flushes as well as allowing
      # elasticsearch to finish processing everything.
      Stud::try(10.times) do
        ftw = FTW::Agent.new
        data = ""
        response = ftw.get!("http://127.0.0.1:#{embedded_http_port}/#{index}/_count?q=*")
        response.read_body { |chunk| data << chunk }
        count = JSON.parse(data)["count"]
        insist { count } == event_count
      end

      puts "Rate: #{event_count / @duration}/sec"
    end
  end
end
