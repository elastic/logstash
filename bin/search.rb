#!/usr/bin/ruby
#
require "rubygems"
require "socket"
require "lib/net/message"
require "lib/net/client"
require "lib/net/messages/directory"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/searchhits"
require "lib/net/messages/ping"
require "set"

Thread::abort_on_exception = true

$done = false
$lastid = nil
$count = 0
$time = 0
$start = Time.now.to_f

class SearchClient < LogStash::Net::MessageClient
  attr_accessor :indexers
  attr_reader :hits
  attr_reader :responding
  attr_reader :results

  def initialize(config_file)
    @indexers = Array.new
    @responding = Array.new
    @hits = 0
    @results = []
    @result_mutex = Mutex.new
    config = YAML::load(File.open(config_file).read)
    super(config, "search")
    start
  end

  def start
    # find our indexers
    msg = LogStash::Net::Messages::DirectoryRequest.new
    op = sendmsg("logstash-directory", msg) do |response|
      DirectoryResponseHandler(response)
      :finished
    end

    op.wait_until_finished
  end

  def SearchResponseHandler(msg)
    @result_mutex.synchronize do
      msg.results.each do |result|
        @results << result
      end
      if msg.finished
        @responding << msg.indexer_id
        if @responding.length == @indexers.length
          close
        end
      end
    end
  end

  def SearchHitsResponseHandler(msg)
    @result_mutex.synchronize do
      @hits += msg.hits
    end
  end

  def DirectoryResponseHandler(msg)
    @indexers = msg.indexers
  end

  def search(log_type, query)
    hits_msg = LogStash::Net::Messages::SearchHitsRequest.new
    hits_msg.log_type = log_type
    hits_msg.query = query
    search_msg = LogStash::Net::Messages::SearchRequest.new
    search_msg.log_type = log_type
    search_msg.query = query
    @indexers.each do |i|
      sendmsg(i, hits_msg)
      sendmsg(i, search_msg)
    end
  end
end

def main(args)
  if ARGV.length != 3
    $stderr.puts "Usage: search configfile log_type query"
  end
  client = SearchClient.new(args[0])
  client.search(args[1], args[2])

  # Wait for the client to decide it's done.
  client.run

  # Collate & print results.
  puts "Hits: #{client.hits}"
  puts ""
  puts client.results.sort_by { |r| r[0] }.collect { |r| r[1] }.join("\n")

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
