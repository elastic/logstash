
require 'rubygems'
require 'lib/net/server'
require 'lib/net/message'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/search'
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

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new
      response.id = request.id
      @indexcount += 1

      if @indexcount % 100 == 0
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

      reader = Ferret::Index::IndexReader.new($logs[request.log_type].index_dir)
      search = Ferret::Search::Searcher.new(reader)

      puts reader.fields.join("\n")
      qp = Ferret::QueryParser.new(:fields => reader.fields,
                                   :tokenized_fields => reader.tokenized_fields,
                                   :or_default => false)
      query = qp.parse(request.query)
      results = []
      offset = (request.offset or 0)
      total = request.limit
      limit = 50

      done = false
      while !done
        done = true
        puts "Searching..."

        if total
          limit = [total, limit].min
          total -= limit

          if limit <= 0
            done = true
            next
          end
        end

        search.search_each(query, :limit => limit, :offset => offset,
                           :sort => "@DATE") do |docid, score|
          done = false
          result = reader[docid][:@LINE]
          results << result
        end

        response = LogStash::Net::Messages::SearchResponse.new
        response.id = request.id
        response.results = results
        response.finished = false
        yield response
        results = []
        offset += limit
      end
      response = LogStash::Net::Messages::SearchResponse.new
      response.id = request.id
      response.results = results
      response.finished = true
      yield response
    end

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
