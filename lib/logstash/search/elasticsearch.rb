
require "em-http-request"
require "logstash/namespace"
require "logstash/logging"
require "logstash/event"
require "logstash/search/base"
require "logstash/search/query"
require "logstash/search/result"
require "logstash/search/facetresult"
require "logstash/search/facetresult/histogram"
 
class LogStash::Search::ElasticSearch < LogStash::Search::Base
  public
  def initialize(settings={})
    @host = (settings[:host] || "localhost")
    @port = (settings[:port] || 9200).to_i
    @logger = LogStash::Logger.new(STDOUT)
  end

  public
  def search(query)
    raise "No block given for search call." if !block_given?
    if query.is_a?(String)
      query = LogStash::Search::Query.parse(query)
    end

    # TODO(sissel): only search a specific index?
    http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/_search")

    @logger.info(["Query", query])
    esreq = {
      "sort" => [
        { "@timestamp" => "desc" }
      ],
      "query" => {
        "query_string" => { 
           "query" => query.query_string,
           "default_operator" => "AND"
        } # query_string
      }, # query
      "from" => query.offset,
      "size" => query.count
    } # elasticsearch request

    @logger.info("ElasticSearch Query: #{esreq.to_json}")
    start_time = Time.now
    req = http.get :body => esreq.to_json
    result = LogStash::Search::Result.new
    req.callback do
      data = JSON.parse(req.response)
      result.duration = Time.now - start_time

      @logger.info(["Got search results", 
                   { :query => query.query_string, :duration => data["duration"],
                     :results => data["hits"]["hits"].size }])
      if req.response_header.status != 200
        result.error_message = data["error"] || req.inspect
        @error = data["error"] || req.inspect
      end

      # We want to yield a list of LogStash::Event objects.
      data["hits"]["hits"].each do |hit|
        result.events << LogStash::Event.new(hit["_source"])
      end

      # Total hits this search could find if not limited
      result.total = data["hits"]["total"]
      result.offset = query.offset

      yield result
    end

    req.errback do 
      @logger.warn(["Query failed", query, req, req.response])
      result.duration = Time.now - start_time
      result.error_message = req.response
      #yield result

      yield({ "error" => req.response })
    end
  end # def search

  def histogram(query, field, interval=nil)
    if query.is_a?(String)
      query = LogStash::Search::Query.parse(query)
    end

    # TODO(sissel): only search a specific index?
    http = EventMachine::HttpRequest.new("http://#{@host}:#{@port}/_search")

    @logger.info(["Query", query])
    histogram_settings = {
      "field" => field
    }

    if !interval.nil? && interval.is_a?(Numeric)
      histogram_settings["interval"] = interval
    end

    esreq = {
      "query" => {
        "query_string" => { 
           "query" => query.query_string,
           "default_operator" => "AND"
        } # query_string
      }, # query
      "from" => 0,
      "size" => 0,
      "facets" => {
        "amazingpants" => { # just a name for this histogram...
          "histogram" => histogram_settings,
        },
      },
    } # elasticsearch request

    @logger.info("ElasticSearch Facet Query: #{esreq.to_json}")
    start_time = Time.now
    req = http.get :body => esreq.to_json
    result = LogStash::Search::FacetResult.new
    req.callback do
      data = JSON.parse(req.response)
      result.duration = Time.now - start_time

      @logger.info(["Got search results", 
                   { :query => query.query_string, :duration => data["duration"] }])
      if req.response_header.status != 200
        result.error_message = data["error"] || req.inspect
        @error = data["error"] || req.inspect
      end

      entries = data["facets"]["amazingpants"]["entries"] rescue nil

      if entries.nil? or !data["error"].nil?
        # Use the error message if any, otherwise, return the whole
        # data object as json as the error message for debugging later.
        result.error_message = (data["error"] rescue false) || data.to_json
        yield result
        next
      end
      entries.each do |entry|
        # entry is a hash of keys 'total', 'mean', 'count', and 'key'
        hist_entry = LogStash::Search::FacetResult::Histogram.new
        hist_entry.key = entry["key"]
        hist_entry.count = entry["count"]
        result.results << hist_entry
      end # for each histogram result
      yield result
    end # request callback

    req.errback do 
      @logger.warn(["Query failed", query, req, req.response])
      result.duration = Time.now - start_time
      result.error_message = req.response
      yield result
      #yield({ "error" => req.response })
    end
  end

  def anonymize
    # TODO(sissel): Plugin-ify this (Search filters!)
    # TODO(sissel): Implement
    #  Search anonymization
    #require "digest/md5"
    #data["hits"]["hits"].each do |hit|
    [].each do |hit|
      event = LogStash::Event.new(hit["_source"])
      event.to_hash.each do |key, value|
        next unless value.is_a?(String)
        value.gsub!(/[^ ]+\.loggly\.net/) { |match| "loggly-" + Digest::MD5.hexdigest(match)[0..6]  + ".example.com"}
      end

      event.fields.each do |key, value|
        value = [value] if value.is_a?(String)
        next unless value.is_a?(Array)
        value.each do |v|
          v.gsub!(/[^ ]+\.loggly\.net/) { |match| "loggly-" + Digest::MD5.hexdigest(match)[0..6]  + ".example.com"}
        end # value.each
      end # hit._source.@fields.each
    end # data.hits.hits.each
  end # def anonymize
end # class LogStash::Search::ElasticSearch
