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

class TestOutputElasticSearch < Test::Unit::TestCase
  ELASTICSEARCH_VERSION = "0.15.2"

  def setup
    start_elasticsearch
    #@cluster = "logstash-test-1234"

    @output = LogStash::Outputs::Elasticsearch.new({
      "host" => ["localhost"],
      "index" => ["test"],
      "type" => ["foo"],
      "cluster" => [@cluster],
    })
    @output.register
  end # def setup

  def start_elasticsearch
    # install
    version = self.class::ELASTICSEARCH_VERSION
    system("make -C #{File.dirname(__FILE__)}/../../setup/elasticsearch/ init-elasticsearch-#{version} wipe-elasticsearch-#{version} #{$DEBUG ? "" : "> /dev/null 2>&1"}")

    #1.upto(30) do
      # Pick a random port
      #@port_http = (rand * 30000 + 20000).to_i
      #@port_tcp = (rand * 30000 + 20000).to_i
    #end # try a few times to launch ES on a random port.
    
    # Listen on random ports, I don't need them anyway.
    @port_http = 0
    @port_tcp = 0

    teardown if @es_pid
    @cluster = "logstash-test-#{$$}"

    puts "Starting ElasticSearch #{version}"
    @clusterflags = "-Des.cluster.name=#{@cluster}"

    ENV["ESFLAGS"] = "-Des.http.port=#{@port_http} -Des.transport.tcp.port=#{@port_tcp} "
    ENV["ESFLAGS"] += @clusterflags
    ENV["ESFLAGS"] += " > /dev/null 2>&1" if !$DEBUG
    cmd = ["make", "-C", "#{File.dirname(__FILE__)}/../../setup/elasticsearch/",]
    cmd << "-s" if !$DEBUG
    cmd << "run-elasticsearch-#{version}"
    @es_pid = Spoon.spawnp(*cmd)

    # Assume it's up and happy, or will be.
    #raise "ElasticSearch failed to start or was otherwise not running properly?"
  end # def start_elasticsearch

  def teardown
    # Kill the whole process group for elasticsearch
    Process.kill("KILL", -1 * @es_pid) rescue nil
    Process.kill("KILL", @es_pid) rescue nil

    # TODO(sissel): Until I fix the way elasticsearch server is run,
    # we'll use pkill...
    system("pkill -9 -f 'java.*#{@clusterflags}.*Bootstrap'")
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
      puts "Pushing event: #{e}" if $DEBUG
      @output.receive(e)
    end

    tries = 30 
    es = LogStash::Search::ElasticSearch.new(:cluster => @cluster)
    loop do
      puts "Tries left: #{tries}" if $DEBUG
      query = LogStash::Search::Query.new(:query_string => "*", :count => 5)
      es.search(query, async=false) do |result|
        if events.size == result.events.size
          puts "Found #{result.events.size} events, ready to verify!"
          expected = events.clone
          assert_equal(events.size, result.events.size)
          #events.each { |e| p :expect => e }
          result.events.each do |event|
            assert(expected.include?(event), "Found event in results that was not expected: #{event.inspect}\n\nExpected: #{events.map{ |a| a.inspect }.join("\n")}")
          end

          return
        else
          tries -= 1
          if tries <= 0
            assert(false, "Gave up trying to query elasticsearch. Maybe we aren't indexing properly?")
            return
          end
        end # if events.size == hits.size
      end # es.search

      sleep 0.2
    end # loop
  end # def test_elasticsearch_basic
end # class TestOutputElasticSearch

#class TestOutputElasticSearch0_15_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_15_1

#class TestOutputElasticSearch0_13_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_13_1
