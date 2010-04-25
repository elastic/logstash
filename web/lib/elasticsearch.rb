
require "rubygems"
require "uri"
require "json"
require "ap"
require "logger"
require "httpclient"

class ElasticSearch
  def initialize(host)
    @host = host
    @http = HTTPClient.new
    @logger = Logger.new(STDERR)
  end

  def _get(params, what, path = "")
    path.gsub!(/\/+$/, "")
    uri = URI.escape("http://#{@host}#{path}/_#{what}")
    @logger.info("URL for #{what}: #{uri}")
    @logger.info("Body: #{params.to_json}");
    # ElasticSearch uses "GET" with body, so we can't call .get() here.
    response = @http.request(:get, uri, query = nil, body = params.to_json)

    if response.status != 200
      ap JSON.parse(response.content)
      raise "Search failure (http code #{response.code})"
    end
    return JSON.parse(response.content)
  end

  def query(query, path = "")
    return ElasticSearch::SearchResults.new(_get(query, "search", path))
  end # def query

  def count(query, path = "")
    return _get(query, "count", path)["count"]
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
  #ap es.query( { :query => { :field => { :progname => "etl-cron"} } }).results
  #ap es.query( { :query => { :field => { :@DATE => 1272164175} } }).results
  ap es.query( 
      { :query => 
        {"bool" => {"must" => [{"query_string" => {"query" => ARGV[0],"default_field" => "@LINE"}},{"range" => {"@DATE" => {"to" => Time.now.to_i,"from" => Time.now.to_i - 600}}}]}}
      }
  )
end
      #:bool => { :must => [
        #{ :range => { :@DATE => { :from => 1272164175, :to => 1272164176,} } },
        ##{ :field => { :progname => "etl-cron" } },
        #{ :query_string => { :query => "progname:etl-cron", :default_field => "@LINE" } },
      #] },
    #} 
