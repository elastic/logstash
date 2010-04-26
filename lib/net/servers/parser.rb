require 'rubygems'
#require 'net/http'
#require 'curb'
require 'em-http'

require 'lib/config/indexer.rb'
require 'lib/log/text'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/ping'
require 'lib/net/messages/search'
require 'lib/net/messages/searchhits'
require 'mqrpc'
require 'pp'

class EventMachine::Protocols::HttpClient2::Request
  def __send_request
    az = @args[:authorization] and az = "Authorization: #{az}\r\n"

    is_post = (@args[:post_body] != nil)
    r = [
      "#{@args[:verb]} #{@args[:uri]} HTTP/#{@args[:version] || "1.1"}",
      "Host: #{@args[:host_header] || "_"}",
    ]

    r << az if az

    if is_post
      r << "Content-Length: #{@args[:post_body].length}"
      r << "Content-Type: application/json"
    end

    # end of request
    r << ""

    # Put post body
    if is_post
      r << @args[:post_body]
    end

    @conn.send_data r.join("\r\n")
  end
end

module LogStash; module Net; module Servers
  class Parser < MQRPC::Agent
    handle LogStash::Net::Messages::IndexEventRequest, :IndexEventRequestHandler
    handle LogStash::Net::Messages::IndexEventResponse, :IndexEventResponseHandler

    def initialize(configfile, logger)
      @config = LogStash::Config::IndexerConfig.new(configfile)
      @logger = logger
      @logger.progname = "parser"
      MQRPC::logger = @logger
      super(@config)
      @lines = Hash.new { |h,k| h[k] = 0 }
      @indexcount = 0
      @starttime = Time.now
      #@elasticsearchconn = EventMachine::Protocols::HttpClient2.connect("127.0.0.1", 9200)
      @elasticsearchconn = \
        EventMachine::HttpRequest.new("http://127.0.0.1:9200/log/stash")
    end

    def IndexEventRequestHandler(request)
      @logger.debug "received IndexEventRequest (for type " \
                    "#{request.log_type}): #{request.log_data}"
      response = LogStash::Net::Messages::IndexEventResponse.new(request)
      @indexcount += 1

      if @indexcount % 100 == 0
        duration = (Time.now.to_f - @starttime.to_f)
        @logger.debug "rate: %.2f/sec" % (@indexcount / duration)
      end

      log_type = request.log_type
      entry = nil
      reason = "unknown; parse_entry returned without an exception"
      begin
        entry = @config.logs[log_type].parse_entry(request.log_data)
      rescue LogStash::Log::LogParseError
        reason = $!
      end

      if !entry
        @logger.warn "Failed parsing line: #{reason}: #{request.log_data}"
        response.code = 1
        response.error = "Entry was #{entry.inspect} (log parsing " \
                         "failed: #{reason})"
        entry = {
          "@NEEDSPARSING" => 1,
          "@LINE" => request.log_data
        }
      else
        response.code = 0
      end
      yield response
      entry["@LOG_TYPE"] = log_type

      # Make a new ID for this request before we forward it.
      #request.generate_id!

      # Now we have a hash for the log data, send it to the indexer
      #request.log_data = entry
      #

      start = Time.now
      req = @elasticsearchconn.post({ 
        #:uri => "/log/stash",
        #:post_body => entry.to_json,
        :body => entry.to_json,
      })
      req.callback do |response|
        #@logger.debug "Duration f" +  response.response_header.status
        @logger.debug "Duration: #{Time.now - start}"
      end

      # Push our message onto the queue
      #curl = Curl::Easy.new("http://localhost:9200/log/stash")
      #curl.headers["Content-Type"] = "application/json"
      #curl.post_body = entry.to_json
      #s = Time.now
      #@logger.debug "Starting index request"
      #curl.perform
      #@logger.debug "Response: #{curl.response_code} #{curl.body_str}"
      #@logger.debug "Duration: #{Time.now - s}"
      #@logger.debug "Duration: " + curl.methods.grep(/_time$/).sort.collect { |a| [a, curl.send(a)] }.join(", ")

    end

    def IndexEventResponseHandler(response)
      # This message comes from the indexer, we don't need to really
      # do anything with it.
    end

    def PingRequestHandler(request)
      @logger.debug "received PingRequest (#{request.pingdata})"
      response = LogStash::Net::Messages::PingResponse.new(request)
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
