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

require "tmpdir"
#require "spoon" # rubygem 'spoon' - implements posix_spawn via FFI

class TestOutputElasticSearch < Test::Unit::TestCase
  ELASTICSEARCH_VERSION = "0.16.0"

  def setup
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir) do
      @output = LogStash::Outputs::Elasticsearch.new({
        "type" => ["foo"],
        "embedded" => ["true"],
      })
      @output.register
    end
  end # def setup

  def teardown
    @output.teardown
    if @tmpdir !~ /^\/tmp/
      $stderr.puts("Tempdir is '#{@tmpdir}' - not in /tmp, I won't " \
                   "remove in case it's not safe.")
    else
      FileUtils.rm_r(@tmpdir)
    end
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
  end # def test_elasticsearch_basic
end # class TestOutputElasticSearch

#class TestOutputElasticSearch0_15_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_15_1

#class TestOutputElasticSearch0_13_1 < TestOutputElasticSearch
  #ELASTICSEARCH_VERSION = self.name[/[0-9_]+/].gsub("_", ".")
#end # class TestOutputElasticSearch0_13_1
