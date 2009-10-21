#!/usr/bin/ruby
#
require "rubygems"
require "lib/net/message"
require "lib/net/client"
require "lib/config/base"
require "lib/net/messages/directory"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/searchhits"
require "lib/net/messages/ping"
require "set"


module LogStash::Net::Clients
  class Search < LogStash::Net::MessageClient
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
      config = LogStash::Config::BaseConfig.new(config_file)
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

    def search(options)
      hits_msg = LogStash::Net::Messages::SearchHitsRequest.new
      hits_msg.log_type = options[:log_type]
      hits_msg.query = options[:query]
      search_msg = LogStash::Net::Messages::SearchRequest.new
      search_msg.log_type = options[:log_type]
      search_msg.query = options[:query]
      search_msg.limit = options[:limit]
      search_msg.offset = options[:offset]
      hits = 0
      results = []
      ops = []
      @indexers.each do |i|
        ops << sendmsg(i, hits_msg) do |msg|
          hits += msg.hits
          :finished
        end
        ops << sendmsg(i, search_msg) do |msg|
          msg.results.each do |result|
            results << result
          end
          :finished if msg.finished
        end
      end

      ops.each do |op|
        op.wait_until_finished
      end

      return [hits, results]
    end
end; end # class LogStash::Net::Clients::Search

