require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/search/elasticsearch"
require "logstash/search/query"

# For checking elasticsearch health
require "net/http"
require "uri"
require "json"

class TestOutputElasticSearch < LogStash::TestCase
  ELASTICSEARCH_VERSION = "0.14.4"

  def start_elasticsearch
    # install
    version = self.class::ELASTICSEARCH_VERSION
    system("make -C #{File.dirname(__FILE__)}/../../setup/elasticsearch/ init-elasticsearch-#{version} wipe-elasticsearch-#{version} #{$DEBUG ? "" : "> /dev/null 2>&1"}")


    1.upto(30) do
      # Pick a random port
      teardown if @es_pid
      @port = (rand * 30000 + 20000).to_i
      @es_pid = Process.fork do
        Process.setsid
        puts "Starting ElasticSearch #{version}"
        if !$DEBUG
          $stdout.reopen("/dev/null", "w")
          $stderr.reopen("/dev/null", "w")
          $stdin.reopen("/dev/null", "r")
        end
        ENV["ESFLAGS"] = "-Des.http.port=#{@port} -Des.transport.tcp.port=0 -Des.cluster.name=logstash-test-#{$$}"
        exec("make", "-C", "#{File.dirname(__FILE__)}/../../setup/elasticsearch/", "run-elasticsearch-#{version}")
        $stderr.puts "Something went wrong starting up elasticsearch?"
        exit 1
      end

      # Wait for elasticsearch to be ready.
      1.upto(30) do
        begin
          Net::HTTP.get(URI.parse("http://localhost:#{@port}/_status"))
          puts "ElasticSearch is ready..."
          return
        rescue => e
          # TODO(sissel): Need to waitpid to see if ES has died and
          # should immediately retry if it has.
          puts "ElasticSearch not yet ready... sleeping."
          sleep 2
        end
      end

      puts "ES did not start properly, trying again."
    end # try a few times to launch ES on a random port.

    raise "ElasticSearch failed to start or was otherwise not running properly?"
  end # def start_elasticsearch

  def teardown
    # Kill the whole process group for elasticsearch
    Process.kill("KILL", -1 * @es_pid) if !@es_pid.nil?
  end # def teardown

  def em_setup
    start_elasticsearch

    config = {
      "inputs" => {
        @type => [
          "internal:///"
        ]
      },
      "outputs" => [
        "elasticsearch://localhost:#{@port}/logstashtesting/logs"
      ]
    }

    super(config)
  end # def em_setup

  def test_elasticsearch_basic
    EventMachine::run do
      em_setup

      # TODO(sissel): I think em-http-request may cross signals somehow
      # if there are multiple requests to the same host/port?
      # Confusing. If we don't sleep here, then the setup fails and blows
      # a fail to configure exception.
      EventMachine::add_timer(3) do

        events = []
        myfile = File.basename(__FILE__)
        1.upto(5).each do |i|
          events << LogStash::Event.new("@message" => "just another log rollin' #{i}",
                                        "@source" => "logstash tests in #{myfile}")
        end

        # TODO(sissel): Need a way to hook when the agent is ready?
        EventMachine.next_tick do
          events.each do |e|
            @input.push e
          end
        end # next_tick, push our events

        tries = 30 
        EventMachine.add_periodic_timer(0.2) do
          es = LogStash::Search::ElasticSearch.new(:port => @port, :host => "localhost")
          query = LogStash::Search::Query.new(:query_string => "*", :count => 5)
          es.search(query) do |result|
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
        end # add_periodic_timer(0.2) / query elasticsearch
      end # sleep for 3 seconds before going to allow the registration to work.
    end # EventMachine::run
  end # def test_elasticsearch_basic
end # class TestOutputElasticSearch

#class TestOutputElasticSearch0_13_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_13_1
#
#class TestOutputElasticSearch0_12_0 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_12_0
