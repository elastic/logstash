
require "rubygems"
require "uri"
require "json"
require "logger"
require "httpclient"

class ElasticSearch
  def initialize(host)
    @host = host
    @http = HTTPClient.new
    @logger = Logger.new(STDERR)
  end

  def _get(query, what)
    index = URI.escape("#{query[:base]}/#{query[:log_type]}")
    uri = "http://#{@host}/#{index}/_#{what}?"
    params = query.collect { |k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}" }.join("&")
    uri += "#{params}"
    @logger.info("URL for #{what}: #{uri}")
    response = @http.get(uri)

    if response.status != 200
      p JSON.parse(response.content)
      raise "Search failure (http code #{response.code})"
    end
    return JSON.parse(response.content)
  end

  def query(query)
    return ElasticSearch::SearchResults.new(_get(query, "search"))
  end # def query

  def count( query)
    return _get(query, "count")["count"]
  end
end

class ElasticSearch::SearchResults
  attr_reader :hits
  attr_reader :results

  def initialize(data)
    @hits = data["hits"]["total"]
    @results = data["hits"]["hits"]
  end
end

if __FILE__ == $0
  require "ap"
  es = ElasticSearch.new("localhost:9200")
  ap es.query(:base => "logstash", :log_type => "linux-syslog", :q => "progname:etl-cron").results
end
