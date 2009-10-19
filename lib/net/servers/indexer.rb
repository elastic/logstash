
require 'rubygems'
require 'lib/net/server'
require 'lib/net/message'
require 'lib/net/messages/broadcast'
require 'lib/net/messages/directory'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/logkeys'
require 'lib/net/messages/logtypes'
require 'lib/net/messages/search'
require 'lib/net/messages/searchhits'
require 'lib/net/messages/quit'
require 'lib/net/messages/ping'
require 'lib/config/indexer.rb'
require 'ferret'
require 'lib/log/text'
require 'pp'

module LogStash; module Net; module Servers
  class Indexer < LogStash::Net::MessageServer
    BROADCAST_INTERVAL = 5
    SYNC_DELAY = 10

    def initialize(configfile)
      @config = LogStash::Config::IndexerConfig.new(configfile)
      super() # PASSARGS
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

    def QuitRequestHandler(request)
      $stderr.puts "Got quit message, exiting..."
      close
    end

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new
      response.id = request.id
      @indexcount += 1

      if @indexcount % 100 == 0
        duration = (Time.now.to_f - @starttime.to_f)
        puts "rate: %.2f/sec" % (@indexcount / duration)
      end

      log_type = request.log_type

      if not @indexes.member?(log_type)
        @indexes[log_type] = @config.logs[log_type].get_index
      end

      #puts request.log_data.inspect
      #puts @indexes[log_type].class
      @indexes[log_type] << request.log_data
    end

    def PingRequestHandler(request)
      response = LogStash::Net::Messages::PingResponse.new
      response.id = request.id
      response.pingdata = request.pingdata
      yield response
    end

    def LogTypesRequestHandler(request)
      response = LogStash::Net::Messages::LogTypesResponse.new
      response.types = @config.logs.types
      yield response
    end

    def LogKeysRequestHandler(request)
      reader, search, qp = get_ferret(request.log_type)
      response = LogStash::Net::Messages::LogKeysResponse.new
      response.keys = reader.fields
      response.log_type = request.log_type
      yield response
    end

    def get_ferret(log_type)
      @readers[log_type] ||= Ferret::Index::IndexReader.new(
                               @config.logs[log_type].index_dir)
      reader = @readers[log_type]
      @searchers[log_type] ||= Ferret::Search::Searcher.new(reader)
      @qps[log_type] ||= Ferret::QueryParser.new(
                           :fields => reader.fields,
                           :tokenized_fields => reader.tokenized_fields,
                           :or_default => false)
      return @readers[log_type], @searchers[log_type], @qps[log_type]
    end

    def SearchRequestHandler(request)
      puts "Search for #{request.query.inspect} in #{request.log_type}"
      response = LogStash::Net::Messages::SearchResponse.new
      response.id = request.id
      response.indexer_id = @id

      if @config.logs[request.log_type].nil?
        $stderr.puts "invalid log type: #{request.log_type}"
        response.results = []
        response.finished = true
        yield response
        return
      end

      reader, search, qp = get_ferret(request.log_type)
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
        part_response = LogStash::Net::Messages::SearchResponse.new
        part_response.id = request.id
        part_response.results = results
        part_response.finished = false
        yield part_response
        results = []
        offset += count
      end
      response.results = []
      response.finished = true
      yield response
      puts "Search done."
    end # def SearchRequestHandler

    def SearchHitsRequestHandler(request)
      puts "Search for hits on #{request.query.inspect}"
      response = LogStash::Net::Messages::SearchHitsResponse.new
      response.id = request.id
      if @config.logs[request.log_type].nil?
        puts "invalid log type: #{request.log_type}"
        response.hits = 0
        yield response
        return 
      end

      reader = Ferret::Index::IndexReader.new(@config.logs[request.log_type].index_dir)
      search = Ferret::Search::Searcher.new(reader)
      qp = Ferret::QueryParser.new(:fields => reader.fields,
                                   :tokenized_fields => reader.tokenized_fields,
                                   :or_default => false)
      query = qp.parse(request.query)
      offset = (request.offset or 0)

      # search_each returns number of hits, even if we don't yield them.
      hits = search.search_each(query, :limit => 1, :offset => offset,
                                :sort => "@DATE") { |docid, score| }
      response.hits = hits
      yield response
    end # def SearchHitsRequestHandler

    def BroadcastMessageHandler(request)
      @indexers_mutex.synchronize do
        @indexers[request.queue] = Time.now
      end
    end

    def DirectoryRequestHandler(request)
      response = LogStash::Net::Messages::DirectoryResponse.new
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
        puts "Subscribing to logstash-directory"
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
            puts "Time's up. Syncing #{log_type}"
            index.flush
            break;
          end

          synctime = Time.now + SYNC_DELAY
        end
        sleep(synctime - Time.now)
      end
    end # def syncer

    def broadcaster
      msg = LogStash::Net::Messages::BroadcastMessage.new
      msg.queue = @id
      loop do
        sendmsg_topic("logstash-broadcast", msg)
        sleep(BROADCAST_INTERVAL)
        @indexers_mutex.synchronize do
          cutoff = Time.now - (BROADCAST_INTERVAL * 2)
          @indexers.each do |queue, heartbeat|
            next if heartbeat > cutoff
            $stderr.puts "dropping indexer #{queue}, last heartbeat at " \
                         "#{Time.at(heartbeat)}"
            @indexers.delete(queue)
          end
        end
      end
    end
  end # Indexer
end; end; end # LogStash::Net::Server
