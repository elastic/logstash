
require "jruby-elasticsearch"
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
    @host = (settings[:host] || nil)
    @port = (settings[:port] || 9300).to_i
    @cluster = (settings[:cluster] || nil)
    @logger = LogStash::Logger.new(STDOUT)
    @client = ElasticSearch::Client.new(:host => @host, :port => @port, :cluster => @cluster)
  end

  # See LogStash::Search;:Base#search
  public
  def search(q, async=false)
    raise "No block given for search call." if !block_given?
    if q.is_a?(String)
      q = LogStash::Search::Query.parse(q)
    end

    searchreq = @client.search do
      sort("@timestamp", :desc)
      query(q.query_string, :and)
      offset(q.offset)
      limit(q.count)
    end

    @logger.info("ElasticSearch search: #{q.query_string}")
    start_time = Time.now

    # TODO(sissel): Dedup this into a method.
    if async
      searcreq.execute do |response|
        result = search_response_to_result(response)
        result.offset = q.offset
        result.duration = Time.now - start_time
        @logger.debug(["Got search results (async)", 
                     { :query => q.query_string, :duration => response.took.to_s,
                       :result_count => result.total }])

        yield result
      end
      return
    else # not async
      response = searchreq.execute!
      result = search_response_to_result(response)
      result.offset = q.offset
      result.duration = Time.now - start_time
      @logger.info(["Got search results (in blocking mode)", 
                   { :query => q.query_string, :duration => response.took.to_s,
                     :result_count => result.total }])

      if block_given?
        yield result
      else
        return result
      end
    end # if async
    return
  end # def search

  private
  def search_response_to_result(response)
    result = LogStash::Search::Result.new

    hits = response.hits rescue nil

    if hits.nil? 
      # return the whole object object as json as the error message for
      # debugging later.
      result.error_message = response
      yield result
      next # breaks from this callback
    end

    # We want to yield a list of LogStash::Event objects.
    hits.each do |hit|
      data = hit.getSource
      # TODO(sissel): this conversion is only necessary because
      # LogStash::Event#== invokes == on the data hash, and in in the
      # test suite, we'll have a ruby array of tags compared against
      # a java.util.ArrayList, which always fails.
      # Possible fixes: 
      #   - make Event#== smarter
      #   - or, convert in the test (not as awesome)
      data["@tags"] = data["@tags"].to_a # convert java ArrayList to Ruby
      result.events << LogStash::Event.new(data)
    end

    # Total hits this search could find if not limited
    result.total = hits.totalHits
    return result
  end # def search_response_to_result

  # See LogStash::Search;:Base#histogram
  public
  def histogram(q, field, interval=nil, async=false)
    raise "No block given for search call." if async && !block_given?
    if q.is_a?(String)
      q = LogStash::Search::Query.parse(q)
    end

    name = "happyhisto"
    searchreq = @client.search do
      query(q.query_string, :and)
      histogram(field, interval, name)
      limit(10)
    end

    @logger.info("ElasticSearch Facet Query: #{q.query_string}")
    start_time = Time.now

    process = lambda do |response|
      result = LogStash::Search::FacetResult.new
      result.duration = Time.now - start_time

      @logger.info(["Got search results", 
                   { :query => q.query_string, :duration => response.took.to_s }])
      # TODO(sissel): Check for error.

      entries = response.facets.facet(name).entries

      if entries.nil?
        # return the whole response object as the error message for debugging
        # later.
        result.error_message = response
        return result
      end

      entries.each do |entry|
        # entry is a hash of keys 'total', 'mean', 'count', and 'key'
        hist_entry = LogStash::Search::FacetResult::Histogram.new
        hist_entry.key = entry.key
        hist_entry.count = entry.count
        hist_entry.mean = entry.mean
        hist_entry.total = entry.total
        p :histo => hist_entry
        result.results << hist_entry
      end # for each histogram result
      return result
    end # lambda 'process'

    if async
      searchreq.execute do |response|
        yield process.call(response)
      end # request callback
    else 
      # async == false
      return process.call(searchreq.execute!)
    end # if async
  end # def histogram

  # Not used. Needs refactoring elsewhere.
  private
  def __anonymize
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
  end # def __anonymize
end # class LogStash::Search::ElasticSearch
