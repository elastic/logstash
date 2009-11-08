#!/usr/bin/ruby
#
require "rubygems"
require "lib/config/base"
require "lib/net/messages/directory"
require "lib/net/messages/indexevent"
require "lib/net/messages/search"
require "lib/net/messages/searchhits"
require "lib/net/messages/ping"
require "set"


module LogStash::Net::Clients
  class Search < MQRPC::Agent
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
      super(config)
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
      query = options[:query]
      # Also skip things that need parsing when searching, by default.
      if !query.include?("@NEEDSPARSING")
        query = "(#{query}) AND -@NEEDSPARSING:1"
      end

      @logger.info "Query: #{query}"

      hits_msg = LogStash::Net::Messages::SearchHitsRequest.new
      hits_msg.log_type = options[:log_type]
      hits_msg.query = query
      search_msg = LogStash::Net::Messages::SearchRequest.new
      search_msg.log_type = options[:log_type]
      search_msg.query = query
      search_msg.limit = options[:limit]
      search_msg.offset = options[:offset]
      hits = 0
      results = []
      ops = []
      @indexers.each do |i|
        ops << sendmsg(i, hits_msg) do |msg|
          @logger.debug "Got #{msg.class} with age #{msg.age}"
          hits += msg.hits
          :finished
        end
        ops << sendmsg(i, search_msg) do |msg|
          @logger.debug "Got #{msg.class} with age #{msg.age}"
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

    def searchhits(log_type, queries)
      if !queries.is_a?(Array)
        queries = [queries]
      end


      hits = Hash.new { |h,k| h[k] = 0 }
      ops = []

      queries.each do |query|
        options = {
          :query => query,
          :log_type => log_type,
        }

        # Also skip things that need parsing when searching, by default.
        if !query.include?("@NEEDSPARSING")
          realquery = "(#{query}) AND -@NEEDSPARSING:1"
        else
          realquery = query
        end

        @logger.info "Query: #{realquery}"

        hits_msg = LogStash::Net::Messages::SearchHitsRequest.new
        hits_msg.log_type = options[:log_type]
        hits_msg.query = realquery
        @indexers.each do |i|
          ops << sendmsg(i, hits_msg) do |msg|
            @logger.debug "Got #{msg.class} with age #{msg.age} (query: #{query})"
            hits[query] += msg.hits
            @logger.debug "Hits: #{msg.hits}"
            :finished
          end
        end
      end

      remaining = ops.length
      ops.each do |op|
        op.wait_until_finished
        remaining -=1 
        @logger.debug "Waiting for #{remaining} operations"
      end

      return hits
    end
end; end # class LogStash::Net::Clients::Search

