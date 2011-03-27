require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/outputs/elasticsearch"
require "logstash/search/elasticsearch"
require "logstash/search/query"

require "spoon" # rubygem 'spoon' - implements posix_spawn via FFI

class TestOutputElasticSearch < LogStash::TestCase
  ELASTICSEARCH_VERSION = "0.15.2"

  def setup
    #start_elasticsearch
    @cluster_name = "logstash-test-1234"

    @output = LogStash::Outputs::Elasticsearch.new({
      "host" => ["localhost"],
      "index" => ["test"],
      "type" => ["foo"],
      "cluster" => [@cluster_name],
    })
    @output.register
  end # def setup

  def start_elasticsearch
    # install
    version = self.class::ELASTICSEARCH_VERSION
    system("make -C #{File.dirname(__FILE__)}/../../setup/elasticsearch/ init-elasticsearch-#{version} wipe-elasticsearch-#{version} #{$DEBUG ? "" : "> /dev/null 2>&1"}")

    1.upto(30) do
      # Pick a random port
      teardown if @es_pid
      @port_http = (rand * 30000 + 20000).to_i
      @port_tcp = (rand * 30000 + 20000).to_i
      @cluster_name = "logstash-test-#{$$}"
      puts "Starting ElasticSearch #{version}"
      ENV["ESFLAGS"] = "-Des.http.port=#{@port_http} -Des.transport.tcp.port=#{@port_tcp} -Des.cluster.name=#{@cluster_name}"
      @es_pid = Spoon.spawnp("make", "-C", "#{File.dirname(__FILE__)}/../../setup/elasticsearch/", "run-elasticsearch-#{version}")

      # Assume it's up and happy
      return

      # Wait for elasticsearch to be ready.
      #1.upto(30) do
        #begin
          #Net::HTTP.get(URI.parse("http://localhost:#{@port}/_status"))
          #puts "ElasticSearch is ready..."
          #return
        #rescue => e
          ## TODO(sissel): Need to waitpid to see if ES has died and
          ## should immediately retry if it has.
          #puts "ElasticSearch not yet ready... sleeping."
          #sleep 2
        #end
      #end

      #puts "ES did not start properly, trying again."
    end # try a few times to launch ES on a random port.

    raise "ElasticSearch failed to start or was otherwise not running properly?"
  end # def start_elasticsearch

  def teardown
    # Kill the whole process group for elasticsearch
    Process.kill("KILL", -1 * @es_pid) if !@es_pid.nil?
    Process.kill("KILL", @es_pid) if !@es_pid.nil?
  end # def teardown

  def test_elasticsearch_basic
    events = []
    myfile = File.basename(__FILE__)
    1.upto(5).each do |i|
      events << LogStash::Event.new("@message" => "just another log rollin' #{i}",
                                    "@source" => "logstash tests in #{myfile}")
    end

    # TODO(sissel): Need a way to hook when the agent is ready?
    events.each do |e|
      puts "Pushing event: #{e}"
      @output.receive(e)
    end

    tries = 30 
    puts "Starting search client..."
    es = LogStash::Search::ElasticSearch.new(:cluster_name => @cluster_name)
    puts "Done"
    loop do
      puts "Tries left: #{tries}"
      query = LogStash::Search::Query.new(:query_string => "*", :count => 5)
      es.search(query) do |result|
        p :result => result
        if events.size == result.events.size
          puts "Found #{result.events.size} events, ready to verify!"
          expected = events.clone
          assert_equal(events.size, result.events.size)
          events.each { |e| p :expect => e }
          result.events.each do |event|
            p :got => event
            assert(expected.include?(event), "Found event in results that was not expected: #{event.inspect}\n\nExpected: #{events.map{ |a| a.inspect }.join("\n")}")
          end
          EventMachine.stop_event_loop
          next # break out
        else
          tries -= 1
          if tries <= 0
            assert(false, "Gave up trying to query elasticsearch. Maybe we aren't indexing properly?")
            EventMachine.stop_event_loop
          end
        end # if events.size == hits.size
      end # es.search

      sleep 0.2
    end # loop
  end # def test_elasticsearch_basic
end # class TestOutputElasticSearch

#class TestOutputElasticSearch0_13_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_13_1
#
#class TestOutputElasticSearch0_12_0 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_12_0
