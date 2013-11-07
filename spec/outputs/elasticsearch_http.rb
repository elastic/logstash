require "test_utils"

describe "outputs/elasticsearch_http" do
  extend LogStash::RSpec

  describe "ship lots of events w/ default index_type" do
    # Generate a random index name
    index = 10.times.collect { rand(10).to_s }.join("")
    type = 10.times.collect { rand(10).to_s }.join("")

    # Write about 10000 events. Add jitter to increase likeliness of finding
    # boundary-related bugs.
    event_count = 10000 + rand(500)
    flush_size = rand(200) + 1

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "#{type}"
        }
      }
      output {
        elasticsearch_http {
          host => "127.0.0.1"
          port => 9200
          index => "#{index}"
          flush_size => #{flush_size}
        }
      }
    CONFIG

    agent do
      # Try a few times to check if we have the correct number of events stored
      # in ES.
      #
      # We try multiple times to allow final agent flushes as well as allowing
      # elasticsearch to finish processing everything.
      ftw = FTW::Agent.new
      ftw.post!("http://localhost:9200/#{index}/_flush")

      # Wait until all events are available.
      Stud::try(10.times) do
        data = ""
        response = ftw.get!("http://127.0.0.1:9200/#{index}/_count?q=*")
        response.read_body { |chunk| data << chunk }
        result = JSON.parse(data)
        count = result["count"]
        insist { count } == event_count
      end

      response = ftw.get!("http://127.0.0.1:9200/#{index}/_search?q=*&size=1000")
      data = ""
      response.read_body { |chunk| data << chunk }
      result = JSON.parse(data)
      result["hits"]["hits"].each do |doc|
        # With no 'index_type' set, the document type should be the type
        # set on the input
        insist { doc["_type"] } == type
        insist { doc["_index"] } == index
        insist { doc["_source"]["message"] } == "hello world"
      end
    end
  end

  describe "testing index_type" do
    describe "no type value" do
      # Generate a random index name
      index = 10.times.collect { rand(10).to_s }.join("")
      event_count = 100 + rand(100)
      flush_size = rand(200) + 1

      config <<-CONFIG
        input {
          generator {
            message => "hello world"
            count => #{event_count}
          }
        }
        output {
          elasticsearch_http {
            host => "127.0.0.1"
            index => "#{index}"
            flush_size => #{flush_size}
          }
        }
      CONFIG

      agent do
        ftw = FTW::Agent.new
        ftw.post!("http://localhost:9200/#{index}/_flush")

        # Wait until all events are available.
        Stud::try(10.times) do
          data = ""
          response = ftw.get!("http://127.0.0.1:9200/#{index}/_count?q=*")
          response.read_body { |chunk| data << chunk }
          result = JSON.parse(data)
          count = result["count"]
          insist { count } == event_count
        end

        response = ftw.get!("http://127.0.0.1:9200/#{index}/_search?q=*&size=1000")
        data = ""
        response.read_body { |chunk| data << chunk }
        result = JSON.parse(data)
        result["hits"]["hits"].each do |doc|
          insist { doc["_type"] } == "logs"
        end
      end
    end

    describe "default event type value" do
      # Generate a random index name
      index = 10.times.collect { rand(10).to_s }.join("")
      event_count = 100 + rand(100)
      flush_size = rand(200) + 1

      config <<-CONFIG
        input {
          generator {
            message => "hello world"
            count => #{event_count}
            type => "generated"
          }
        }
        output {
          elasticsearch_http {
            host => "127.0.0.1"
            index => "#{index}"
            flush_size => #{flush_size}
          }
        }
      CONFIG

      agent do
        ftw = FTW::Agent.new
        ftw.post!("http://localhost:9200/#{index}/_flush")

        # Wait until all events are available.
        Stud::try(10.times) do
          data = ""
          response = ftw.get!("http://127.0.0.1:9200/#{index}/_count?q=*")
          response.read_body { |chunk| data << chunk }
          result = JSON.parse(data)
          count = result["count"]
          insist { count } == event_count
        end

        response = ftw.get!("http://127.0.0.1:9200/#{index}/_search?q=*&size=1000")
        data = ""
        response.read_body { |chunk| data << chunk }
        result = JSON.parse(data)
        result["hits"]["hits"].each do |doc|
          insist { doc["_type"] } == "generated"
        end
      end
    end
  end
end
