require "em-http-request"
require "logstash/namespace"
require "logstash/logging"
require "logstash/event"
require "logstash/search/base"
require "logstash/search/query"
require "logstash/search/result"
require "logstash/search/facetresult"
require "logstash/search/facetresult/histogram"

# TODO(sissel): This won't work anymore (we don't use EM right now)
 
class LogStash::Search::Twitter < LogStash::Search::Base
  public
  def initialize(settings={})
    @host = (settings[:host] || "search.twitter.com")
    @port = (settings[:port] || 80).to_i
    @logger = LogStash::Logger.new(STDOUT)
  end

  public
  def search(query)
    raise "No block given for search call." if !block_given?
    if query.is_a?(String)
      query = LogStash::Search::Query.parse(query)
    end

    # TODO(sissel): only search a specific index?
    http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/search.json?q=#{URI.escape(query.query_string)}&rpp=#{URI.escape(query.count) rescue query.count}")

    @logger.info(["Query", query])

    start_time = Time.now
    req = http.get

    result = LogStash::Search::Result.new
    req.callback do
      data = JSON.parse(req.response)
      result.duration = Time.now - start_time

      hits = (data["results"] || nil) rescue nil

      if hits.nil? or !data["error"].nil?
        # Use the error message if any, otherwise, return the whole
        # data object as json as the error message for debugging later.
        result.error_message = (data["error"] rescue false) || data.to_json
        yield result
        next
      end

      hits.each do |hit|
        hit["@message"]  = hit["text"]
        hit["@timestamp"] = hit["created_at"]
        hit.delete("text")
      end

      @logger.info(["Got search results", 
                   { :query => query.query_string, :duration => data["duration"],
                     :result_count => hits.size }])

      if req.response_header.status != 200
        result.error_message = data["error"] || req.inspect
        @error = data["error"] || req.inspect
      end

      # We want to yield a list of LogStash::Event objects.
      hits.each do |hit|
        result.events << LogStash::Event.new(hit)
      end

      # Total hits this search could find if not limited
      result.total = hits.size
      result.offset = 0

      yield result
    end

    req.errback do 
      @logger.warn(["Query failed", query, req, req.response])
      result.duration = Time.now - start_time
      result.error_message = req.response

      yield result
    end
  end # def search

  def histogram(query, field, interval=nil)
    # Nothing to histogram.
    result = LogStash::Search::FacetResult.new
    yield result
  end
end # class LogStash::Search::ElasticSearch
