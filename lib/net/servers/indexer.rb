
require 'rubygems'
require 'lib/net/server'
require 'lib/net/message'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/search'
require 'lib/net/messages/searchhits'
require 'lib/net/messages/quit'
require 'lib/net/messages/ping'
require 'ferret'
require 'lib/log/text'
require 'config'

module LogStash; module Net; module Servers
  class Indexer < LogStash::Net::MessageServer
    SYNCDELAY = 3

    def initialize(*args)
      # 'super' is not the same as 'super()', and we want super().
      super(*args)
      @indexes = Hash.new
      @lines = Hash.new { |h,k| h[k] = 0 }
      @indexcount = 0
      @starttime = Time.now
    end

    def QuitRequestHandler(request)
      puts "Got quit message, exiting..."
      close
    end

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new
      response.id = request.id
      @indexcount += 1

      if @indexcount % 10 == 0
        duration = (Time.now.to_f - @starttime.to_f)
        puts "%.2f" % (@indexcount / duration)
      end

      log_type = request.log_type
      entry = $logs[log_type].parse_entry(request.log_data)
      if !entry
        response.code = 1
        response.error = "Entry was #{entry.inspect} (log parsing failed)"
        entry = {
          "@NEEDSPARSING" => 1,
          "@LINE" => request.log_data
        }
      else
        response.code = 0
      end

      if not @indexes.member?(log_type)
        @indexes[log_type] = $logs[log_type].get_index
      end

      entry["@LOG_TYPE"] = log_type
      @indexes[log_type] << entry

      if response.code != 0
        yield response
      end
    end

    def PingRequestHandler(request)
      response = LogStash::Net::Messages::PingResponse.new
      response.id = request.id
      response.pingdata = request.pingdata
      yield response
    end

    def SearchRequestHandler(request)
      puts "Search for #{request.query.inspect}"
      response = LogStash::Net::Messages::SearchResponse.new
      response.id = request.id

      if $logs[request.log_type].nil?
        puts "invalid log type: #{request.log_type}"
        response.results = []
        response.finished = true
        puts response.inspect
        yield response
        return
      end
      reader = Ferret::Index::IndexReader.new($logs[request.log_type].index_dir)
      search = Ferret::Search::Searcher.new(reader)
      qp = Ferret::QueryParser.new(:fields => reader.fields,
                                   :tokenized_fields => reader.tokenized_fields,
                                   :or_default => false)
      query = qp.parse(request.query)
      offset = (request.offset or 0)
      total = request.limit
      max_limit = 50
      results = []
      limit = max_limit
      # TODO(sissel): We need a way to say 'flush now' because this
      # method will batch search results due to the likely efficiency
      # in searching for batches of results.

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
          results << result
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
      puts response.inspect
      yield response
    end # def SearchRequestHandler

    def SearchHitsRequestHandler(request)
      puts "Search for #{request.query.inspect}"
      response = LogStash::Net::Messages::SearchHitsResponse.new
      response.id = request.id
      if $logs[request.log_type].nil?
        puts "invalid log type: #{request.log_type}"
        response.hits = 0
        yield response
        return 
      end
      reader = Ferret::Index::IndexReader.new($logs[request.log_type].index_dir)
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

    # Special 'run' override because we want sync to disk once per minute.
    def run
      subscribe("logstash")
      @syncer = Thread.new { syncer }
      super
    end # def run

    def syncer
      synctime = Time.now + SYNCDELAY
      loop do
        if Time.now > synctime
          @indexes.each do |log_type,index|
            puts "Time's up. Syncing #{log_type}"
            index.commit
          end

          synctime = Time.now + SYNCDELAY
        end
        sleep(synctime - Time.now)
      end
    end # def syncer
  end # Indexer
end; end; end # LogStash::Net::Server
