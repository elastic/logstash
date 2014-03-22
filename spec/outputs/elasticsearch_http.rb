require "test_utils"

describe "outputs/elasticsearch_http", :elasticsearch => true do
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
      ftw.post!("http://localhost:9200/#{index}/_refresh")

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
        ftw.post!("http://localhost:9200/#{index}/_refresh")

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
        ftw.post!("http://localhost:9200/#{index}/_refresh")

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

  describe "index template expected behavior" do
    subject do
      Elasticsearch::Client.new.indices.delete_template(:name => "*")
      require "logstash/outputs/elasticsearch_http"
      settings = {
        "manage_template" => true,
        "template_overwrite" => true,
        "host" => "localhost"
      }
      output = LogStash::Outputs::ElasticSearchHTTP.new(settings)
      output.register
      next output
    end

    before :each do
      require "elasticsearch"
      @es = Elasticsearch::Client.new
      @es.indices.delete(:index => "*")

      subject.receive(LogStash::Event.new("message" => "sample message here"))
      subject.receive(LogStash::Event.new("somevalue" => 100))
      subject.receive(LogStash::Event.new("somevalue" => 10))
      subject.receive(LogStash::Event.new("somevalue" => 1))
      subject.receive(LogStash::Event.new("country" => "us"))
      subject.receive(LogStash::Event.new("country" => "at"))
      subject.receive(LogStash::Event.new("geoip" => { "location" => [ 0.0, 0.0 ] }))
      subject.buffer_flush(:final => true)
      @es.indices.refresh

      # Wait or fail until everything's indexed.
      Stud::try(20.times) do
        r = @es.search
        insist { r["hits"]["total"] } == 7
      end
    end

    it "permits phrase searching on string fields" do
      results = @es.search(:q => "message:\"sample message\"")
      insist { results["hits"]["total"] } == 1
      insist { results["hits"]["hits"][0]["_source"]["message"] } == "sample message here"
    end

    it "numbers dynamically map to a numeric type and permit range queries" do
      results = @es.search(:q => "somevalue:[5 TO 105]")
      insist { results["hits"]["total"] } == 2

      values = results["hits"]["hits"].collect { |r| r["_source"]["somevalue"] }
      insist { values }.include?(10)
      insist { values }.include?(100)
      reject { values }.include?(1)
    end

    it "creates .raw field fro any string field which is not_analyzed" do
      results = @es.search(:q => "message.raw:\"sample message here\"")
      insist { results["hits"]["total"] } == 1
      insist { results["hits"]["hits"][0]["_source"]["message"] } == "sample message here"

      # partial or terms should not work.
      results = @es.search(:q => "message.raw:\"sample\"")
      insist { results["hits"]["total"] } == 0
    end

    it "make [geoip][location] a geo_point" do
      results = @es.search(:body => { "filter" => { "geo_distance" => { "distance" => "1000km", "geoip.location" => { "lat" => 0.5, "lon" => 0.5 } } } })
      insist { results["hits"]["total"] } == 1
      insist { results["hits"]["hits"][0]["_source"]["geoip"]["location"] } == [ 0.0, 0.0 ]
    end

    it "should index stopwords like 'at' " do
      results = @es.search(:body => { "facets" => { "t" => { "terms" => { "field" => "country" } } } })["facets"]["t"]
      terms = results["terms"].collect { |t| t["term"] }

      insist { terms }.include?("us")

      # 'at' is a stopword, make sure stopwords are not ignored.
      insist { terms }.include?("at")
    end
  end
end
