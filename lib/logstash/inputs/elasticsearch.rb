require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"

# Read from elasticsearch.
#
# This is useful for replay testing logs, reindexing, etc.
#
# Example:
#
#     input {
#       # Read all documents from elasticsearch matching the given query
#       elasticsearch {
#         host => "localhost"
#         query => "ERROR"
#       }
#     }
#
# * TODO(sissel): configurable scroll timeout
# * TODO(sissel): Option to keep the index, type, and doc id so we can do reindexing?
class LogStash::Inputs::Elasticsearch < LogStash::Inputs::Base
  config_name "elasticsearch"
  milestone 1

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :default => 9200

  config :index, :validate => :string, :default => "*"

  config :query, :validate => :string, :default => "*"

  public
  def register
    require "ftw"
    @agent = FTW::Agent.new
    params = {
      "q" => @query,
      "scroll" => "5m",
      "size" => "1000",
    }
    @url = "http://#{@host}:#{@port}/#{@index}/_search?#{encode(params)}"
    @format ||= "json_event"
  end # def register

  private
  def encode(hash)
    return hash.collect do |key, value|
      CGI.escape(key) + "=" + CGI.escape(value)
    end.join("&")
  end # def encode

  public
  def run(output_queue)
    response = @agent.get!(@url)
    json = ""
    response.read_body { |c| json << c }
    result = JSON.parse(json)
    scroll_id = result["_scroll_id"]

    scroll_params = {
      "scroll_id" => scroll_id
    }
    scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode(scroll_params)}"
    while true
      break if result.nil?
      hits = result["hits"]["hits"]
      break if hits.empty?

      result["hits"]["hits"].each do |hit|
        event = LogStash::Event.new(hit["_source"])
        output_queue << event
      end

      # Fetch until we get no hits

      response = @agent.get!(scroll_url)
      json = ""
      response.read_body { |c| json << c }
      result = JSON.parse(json)

      if result["error"]
        @logger.warn(result["error"], :request => scroll_url)
        # TODO(sissel): raise an error instead of breaking
        break
      end
    end
  end # def run
end # class LogStash::Inputs::Elasticsearch
