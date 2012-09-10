require "test_utils"

describe "outputs/elasticsearch_http" do
  extend LogStash::RSpec

  describe "ship lots of events" do
    # Generate a random index name
    index = 10.times.collect { rand(10).to_s }.join("")

    # Write about 10000 events. Add jitter to increase likeliness of finding
    # boundary-related bugs.
    event_count = 10000 + rand(500)
    flush_size = rand(200) + 1

    p :index => index, :event_count => event_count, :flush_size => flush_size

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        elasticsearch_http {
          host => "127.0.0.1"
          port => 9200
          index => "#{index}"
          index_type => "testing"
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
      Stud::try(10.times) do
        ftw = FTW::Agent.new
        data = ""
        response = ftw.get!("http://127.0.0.1:9200/#{index}/_count?q=*")
        response.read_body { |chunk| data << chunk }
        count = JSON.parse(data)["count"]
        insist { count } == event_count
      end

      puts "Rate: #{event_count / @duration}/sec (flush_size: #{flush_size})"
    end
  end
end


    #before :all do
      #puts "Downloading elasticsearch if necessary"
      #system("make vendor-elasticsearch")
      #puts "Spawning ElasticSearch"
      #classpath = Dir.glob("vendor/jar/elasticsearch-*/lib/*.jar").join(":")
      #options = {
        #"foreground" => "yes",
        #"index.store.type" => "memory"
      #}
#
      #es_opts = options.collect { |k,v| "-Des.#{k}=#{v}" }.join(" ")
      #runclass = "org.elasticsearch.bootstrap.ElasticSearch"
      #@es_proc = Spoon.spawnp("sh", "-c", "exec java -cp #{classpath} -Delasticsearch #{es_opts} #{runclass}")
      #reject { @es_proc }.nil?

      # Wait for it to be healthy?
      #require "ftw/agent"
      #ftw = FTW::Agent.new
      #success = false
      #Stud.try(10.times) do
        #puts "Waiting for elasticsearch to come up..."
        #response = ftw.get!("http://127.0.0.1:9200/")
        #response.read_body { |chunk| }
        #if response.status != 200
          #raise "failed"
        #end
        #success = true
      #end
      #raise "elasticsearch never came online?" if !success
    #end # before :all

    #after :all do
      #puts "Killing elasticsearch (pid: #{@es_proc})"
      #Process::kill("KILL", @es_proc)
      #puts "Waiting for elasticsearch to die"
      #Process::wait(@es_proc)
    #end
