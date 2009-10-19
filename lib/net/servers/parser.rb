
require 'rubygems'
require 'lib/net/server'
require 'lib/net/message'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/search'
require 'lib/net/messages/searchhits'
require 'lib/net/messages/quit'
require 'lib/net/messages/ping'
require 'lib/config/indexer.rb'
require 'ferret'
require 'lib/log/text'
require 'pp'

module LogStash; module Net; module Servers
  class Parser < LogStash::Net::MessageServer
    SYNCDELAY = 10

    def initialize(configfile)
      @config = LogStash::Config::IndexerConfig.new(configfile)
      super()
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

      if @indexcount % 100 == 0
        duration = (Time.now.to_f - @starttime.to_f)
        puts "rate: %.2f/sec" % (@indexcount / duration)
      end

      log_type = request.log_type
      entry = @config.logs[log_type].parse_entry(request.log_data)
      if !entry
        puts "Failed parsing line: #{request.log_data}"
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
        @indexes[log_type] = @config.logs[log_type].get_index
      end

      entry["@LOG_TYPE"] = log_type

      # Now we have a hash for the log data, send it to the indexer
      request.log_data = entry
      sendmsg("logstash-index", request)
      #@indexes[log_type] << entry
    end

    def PingRequestHandler(request)
      response = LogStash::Net::Messages::PingResponse.new
      response.id = request.id
      response.pingdata = request.pingdata
      yield response
    end

    # Special 'run' override because we want sync to disk once per minute.
    def run
      subscribe("logstash")
      super
    end # def run
  end # Parser
end; end; end # LogStash::Net::Server
