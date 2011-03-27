
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
    @host = (settings[:host] || "localhost")
    @port = (settings[:port] || 9200).to_i
    @cluster = (settings[:cluster] || nil)
    @logger = LogStash::Logger.new(STDOUT)
    @client = ElasticSearch::Client.new(:host => @host, :port => @port, :cluster => @cluster)
  end

  # See LogStash::Search;:Base#search
  public
  def search(q, blocking=false)
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
    searchreq.execute do |response|
      result = LogStash::Search::Result.new
      result.duration = Time.now - start_time

      hits = response.hits rescue nil

      if hits.nil? 
        # return the whole object object as json as the error message for
        # debugging later.
        result.error_message = response
        yield result
        next # breaks from this callback
      end

      @logger.info(["Got search results", 
                   { :query => q.query_string, :duration => response.took.to_s,
                     :result_count => hits.totalHits}])

      # We want to yield a list of LogStash::Event objects.
      hits.each do |hit|
        result.events << LogStash::Event.new(hit.source)
      end

      # Total hits this search could find if not limited
      result.total = result.totalHits
      result.offset = q.offset

      yield result
    end
  end # def search

  # See LogStash::Search;:Base#histogram
  public
  def histogram(q, field, interval=nil)
    raise "No block given for search call." if !block_given?
    if q.is_a?(String)
      q = LogStash::Search::Query.parse(q)
    end

    name = "happyhisto"
    searchreq = @client.search do
      query(q.query_string, :and)
      histogram(field, interval, name)
      limit(0)
    end

    @logger.info("ElasticSearch Facet Query: #{q.query_string}")
    start_time = Time.now
    searchreq.execute do |response|
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
        yield result
        next
      end

      entries.each do |entry|
        # entry is a hash of keys 'total', 'mean', 'count', and 'key'
        hist_entry = LogStash::Search::FacetResult::Histogram.new
        hist_entry.key = entry.key
        hist_entry.count = entry.count
        hist_entry.mean = entry.mean
        hist_entry.total = entry.total
        result.results << hist_entry
      end # for each histogram result
      yield result
    end # request callback
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
