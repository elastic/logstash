require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/outputs/elasticsearch"
require "logstash/search/elasticsearch"
require "logstash/search/query"

require "tmpdir"

describe LogStash::Outputs::ElasticSearch do
  before do
    FileUtils.rm_r("data") if File.exists?("data")
    @output = LogStash::Outputs::ElasticSearch.new({
      "type" => ["foo"],
      "embedded" => ["true"],
    })
    @output.register
  end # before

  after do
    @output.teardown
    FileUtils.rm_r("data") if File.exists?("data")
  end # after

  test "elasticsearch basic output" do
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
    es = LogStash::Search::ElasticSearch.new(:type => :local)
    while tries > 0
      tries -= 1
      puts "Tries left: #{tries}" if $DEBUG
      query = LogStash::Search::Query.new(:query_string => "*", :count => 5)
      begin
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
      rescue org.elasticsearch.action.search.SearchPhaseExecutionException => e
        # ignore
      end

      sleep 0.2
    end # while tries > 0
  end # test_elasticsearch_basic
end # testing for LogStash::Outputs::ElasticSearch
