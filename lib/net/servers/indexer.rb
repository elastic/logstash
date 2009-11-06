
require 'rubygems'
require 'ferret'
require 'lib/config/indexer.rb'
require 'lib/log/text'
require 'lib/net/messages/broadcast'
require 'lib/net/messages/directory'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/logkeys'
require 'lib/net/messages/logtypes'
require 'lib/net/messages/ping'
require 'lib/net/messages/search'
require 'lib/net/messages/searchhits'
require 'lib/util'
require 'mqrpc'
require 'mqrpc/functions/ping'
require 'pp'

module LogStash; module Net; module Servers
  class Indexer < MQRPC::Agent
    include MQRPC::Functions::Ping
    # Default broadcast interval is 30, but for debugging/testing, sometimes
    # it's nice to set it lower.
    BROADCAST_INTERVAL = (ENV["BROADCAST_INTERVAL"] or 30).to_i
    SYNC_DELAY = 10

    def initialize(configfile, logger)
      @logger = logger
      @logger.progname = "indexer"
      @config = LogStash::Config::IndexerConfig.new(configfile)

      MQRPC::logger = @logger
      super(@config)
      @indexes = Hash.new
      @lines = Hash.new { |h,k| h[k] = 0 }
      @indexcount = 0
      @starttime = Time.now
      @indexers = Hash.new
      @indexers_mutex = Mutex.new
      @readers = Hash.new
      @searchers = Hash.new
      @qps = Hash.new
    end

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new(request)
      @indexcount += 1

      if @indexcount % 100 == 0
        duration = (Time.now.to_f - @starttime.to_f)
        @logger.debug "rate: %.2f/sec" % (@indexcount / duration)
      end

      log_type = request.log_type

      @indexes[log_type] ||= @config.logs[log_type].get_index
      @indexes[log_type] << request.log_data
      response.code = 0
      yield response
    end

    def LogTypesRequestHandler(request)
      @logger.debug "received LogTypesRequest"
      response = LogStash::Net::Messages::LogTypesResponse.new(request)
      response.types = @config.logs.types
      yield response
    end

    def LogKeysRequestHandler(request)
      @logger.debug "received LogKeysRequest"
      reader, search, qp = get_ferret(request.log_type)
      response = LogStash::Net::Messages::LogKeysResponse.new(request)
      response.keys = reader.fields
      response.log_type = request.log_type
      yield response
    end

    def get_ferret(log_type)
      
      # open the index every time otherwise we get stale results.
      reader = Ferret::Index::IndexReader.new(@config.logs[log_type].index_dir)
      searcher = Ferret::Search::Searcher.new(reader)
      @qps[log_type] ||= Ferret::QueryParser.new(
                           :fields => reader.fields,
                           :tokenized_fields => reader.tokenized_fields,
                           :or_default => false)
      #return @readers[log_type], @searchers[log_type], @qps[log_type]
      return reader, searcher, @qps[log_type]
    end

    def SearchRequestHandler(request)
      @logger.debug "received SearchRequest (#{request.query.inspect} in " \
                    "#{request.log_type})"
      @logger.debug "message age is #{request.age} seconds"
      stopwatch = LogStash::StopWatch.new
      response = LogStash::Net::Messages::SearchResponse.new(request)
      response.indexer_id = @id

      if @config.logs[request.log_type].nil?
        @logger.warn "SearchRequest received for invalid log_type: " \
                     "#{request.log_type}"
        response.results = []
        response.finished = true
        yield response
        return
      end

      begin
        reader, search, qp = get_ferret(request.log_type)
      rescue Ferret::FileNotFoundError => e
        $logger.warn "get_ferret failed: #{e.inspect}"
        response.results = []
        response.finished = true
        yield response
        return
      end
      query = qp.parse(request.query)
      offset = (request.offset or 0)
      total = request.limit
      max_limit = 50
      results = []
      limit = max_limit

      done = false
      while !done
        done = true

        if total
          limit = [total, max_limit].min
          total -= limit
          if limit <= 0
            done = true
            next
          end
        end

        count = 0
        search.search_each(query, :limit => limit, :offset => offset,
                           :sort => "@DATE") do |docid, score|
          done = false
          result = reader[docid][:@LINE]
          count += 1
          results << [reader[docid][:@DATE], result]
        end

        if (total and count < limit)
          done = true
        end
        part_response = LogStash::Net::Messages::SearchResponse.new(request)
        part_response.results = results
        part_response.finished = false
        yield part_response
        results = []
        offset += count
      end
      response.results = []
      response.finished = true
      yield response

      @logger.info "SearchRequest for '#{request.query}' took #{stopwatch.to_s(4)}"
    end # def SearchRequestHandler

    def SearchHitsRequestHandler(request)
      @logger.debug "received SearchHitsRequest (#{request.query.inspect} in " \
                    "#{request.log_type})"
      response = LogStash::Net::Messages::SearchHitsResponse.new(request)
      if @config.logs[request.log_type].nil?
        @logger.warn "SearchHitsRequest received for invalid log_type: " \
                     "#{request.log_type}"
        response.hits = 0
        yield response
        return 
      end

      begin
        reader, search, qp = get_ferret(request.log_type)
      rescue Ferret::FileNotFoundError => e
        @logger.warn "get_ferret failed: #{e.inspect}"
        response.hits = 0
        yield response
        return
      end
      query = qp.parse(request.query)
      offset = (request.offset or 0)

      # search_each returns number of hits, even if we don't yield them.
      hits = search.search_each(query, :limit => 1, :offset => offset) { |docid, score| }
      
      response.hits = hits
      yield response
    end # def SearchHitsRequestHandler

    def BroadcastMessageHandler(request)
      @logger.debug "received BroadcastMessage (from #{request.queue})"
      @indexers_mutex.synchronize do
        @indexers[request.queue] = Time.now
      end
    end

    def DirectoryRequestHandler(request)
      @logger.debug "received DirectoryRequest"
      response = LogStash::Net::Messages::DirectoryResponse.new(request)
      response.indexers = @indexers.keys
      yield response
    end

    # Special 'run' override because we have extra things to do:
    #  - listen to generic "logstash-index" queue
    #  - listen for indexer broadcasts  on "logstash-broadcast"
    #  - sync to disk once per minute.
    #  - broadcast our presence to other indexers.
    #  - respond to directory requests
    def run
      subscribe("logstash-index")
      subscribe_topic("logstash-broadcast")
      @syncer = Thread.new { syncer }
      @broadcaster = Thread.new  { broadcaster }
      @directory_responder = Thread.new do
        # We wait to make sure we've seen some broadcasts before we start
        # answering directory requests.

        sleep(BROADCAST_INTERVAL + 5)
        subscribe("logstash-directory")
      end
      super
    end # def run

    def syncer
      synctime = Time.now + SYNC_DELAY
      loop do
        if Time.now > synctime
          @indexes.each do |log_type, index|
            # TODO: only run flush if we need to
            @logger.debug "Forcing a sync of #{log_type}"
            index.flush
          end

          synctime = Time.now + SYNC_DELAY
        end
        sleep(synctime - Time.now)
      end
    end # def syncer

    def broadcaster
      msg = LogStash::Net::Messages::BroadcastMessage.new
      msg.queue = @id
      msg.want_buffer(false)
      loop do
        @logger.info "Sending #{msg.class}"
        sendmsg_topic("logstash-broadcast", msg)
        sleep(BROADCAST_INTERVAL)
        @indexers_mutex.synchronize do
          cutoff = Time.now - (BROADCAST_INTERVAL * 2)
          @indexers.each do |queue, heartbeat|
            next if heartbeat > cutoff
            @logger.warn "dropping indexer #{queue}, last heartbeat at " \
                         "#{Time.at(heartbeat)}"
            @indexers.delete(queue)
          end
        end
      end
    end
  end # Indexer
end; end; end # LogStash::Net::Server
