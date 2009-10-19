#!/usr/bin/ruby
#
require 'rubygems'
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

class Client < LogStash::Net::MessageClient
  attr_accessor :indexers
  attr_reader :hits
  attr_reader :responding
  attr_reader :results

  def initialize(*args)
    @indexers = Array.new
    @responding = Array.new
    @hits = 0
    @results = []
    super(*args)
  end

  def SearchResponseHandler(msg)
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

  def SearchHitsResponseHandler(msg)
    @hits += msg.hits
  end

  def DirectoryResponseHandler(msg)
    @indexers = msg.indexers
    close
  end
end

def main(args)
  client = Client.new

  # Find out what indexers are out there
  msg = LogStash::Net::Messages::DirectoryRequest.new
  client.sendmsg("logstash-directory", msg)
  puts "about to .run"
  client.run
  puts "back from client.run"
  indexers = client.indexers

  # Send queries to each indexer and collect the results
  client = Client.new
  client.indexers = indexers
  hits_msg = LogStash::Net::Messages::SearchHitsRequest.new
  hits_msg.log_type = args[0]
  hits_msg.query = args[1]
  search_msg = LogStash::Net::Messages::SearchRequest.new
  search_msg.log_type = args[0]
  search_msg.query = args[1]
  indexers.each do |indexer|
    puts "Querying #{indexer}"
    client.sendmsg("/queue/#{indexer}", hits_msg)
    client.sendmsg("/queue/#{indexer}", search_msg)
  end
  client.run

  # Collate & print results.
  puts "Hits: #{client.hits}"
  puts ""
  puts client.results.join("\n")

  return 0
end

if $0 == __FILE__
  exit main(ARGV)
end
