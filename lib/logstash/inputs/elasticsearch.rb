# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"

# Read from an Elasticsearch cluster, based on search query results.
# This is useful for replaying test logs, reindexing, etc.
#
# Example:
#
#     input {
#       # Read all documents from Elasticsearch matching the given query
#       elasticsearch {
#         host => "localhost"
#         query => "ERROR"
#       }
#     }
#
# This would create an Elasticsearch query with the following format:
#
#     http://localhost:9200/logstash-*/_search?q=ERROR&scroll=1m&size=1000
#
# * TODO(sissel): Option to keep the index, type, and doc id so we can do reindexing?
class LogStash::Inputs::Elasticsearch < LogStash::Inputs::Base
  config_name "elasticsearch"
  milestone 1

  default :codec, "json"

  # The IP address or hostname of your Elasticsearch server.
  config :host, :validate => :string, :required => true

  # The HTTP port of your Elasticsearch server's REST interface.
  config :port, :validate => :number, :default => 9200

  # The index or alias to search.
  config :index, :validate => :string, :default => "logstash-*"

  # The query to be executed.
  config :query, :validate => :string, :default => "*"

  # Enable the Elasticsearch "scan" search type.  This will disable
  # sorting but increase speed and performance.
  config :scan, :validate => :boolean, :default => true

  # This allows you to set the maximum number of hits returned per scroll.
  config :size, :validate => :number, :default => 1000

  # This parameter controls the keepalive time in seconds of the scrolling
  # request and initiates the scrolling process. The timeout applies per
  # round trip (i.e. between the previous scan scroll request, to the next).
  config :scroll, :validate => :string, :default => "1m"

  public
  def register
    require "ftw"
    @agent = FTW::Agent.new
    params = {
      "q" => @query,
      "scroll" => @scroll,
      "size" => "#{@size}",
    }

    params['search_type'] = "scan" if @scan

    @url = "http://#{@host}:#{@port}/#{@index}/_search?#{encode(params)}"
  end # def register

  private
  def encode(hash)
    return hash.collect do |key, value|
      CGI.escape(key) + "=" + CGI.escape(value)
    end.join("&")
  end # def encode

  public
  def run(output_queue)

    # Execute the search request
    response = @agent.get!(@url)
    json = ""
    response.read_body { |c| json << c }
    result = JSON.parse(json)
    scroll_id = result["_scroll_id"]

    # When using the search_type=scan we don't get an initial result set.
    # So we do it here.
    if @scan

      scroll_params = {
        "scroll" => @scroll
      }

      scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode(scroll_params)}"
      response = @agent.post!(scroll_url, :body => scroll_id)
      json = ""
      response.read_body { |c| json << c }
      result = JSON.parse(json)

    end

    while true
      break if result.nil?
      hits = result["hits"]["hits"]
      break if hits.empty?

      hits.each do |hit|
        event = hit["_source"]

        # Hack to make codecs work
        @codec.decode(event.to_json) do |event|
          decorate(event)
          output_queue << event
        end
      end

      # Get the scroll id from the previous result set and use it for getting the next data set
      scroll_id = result["_scroll_id"]

      # Fetch the next result set
      scroll_params = {
        "scroll" => @scroll
      }
      scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode(scroll_params)}"

      response = @agent.post!(scroll_url, :body => scroll_id)
      json = ""
      response.read_body { |c| json << c }
      result = JSON.parse(json)

      if result["error"]
        @logger.warn(result["error"], :request => scroll_url)
        # TODO(sissel): raise an error instead of breaking
        break
      end

    end
  rescue LogStash::ShutdownSignal
    # Do nothing, let us quit.
  end # def run
end # class LogStash::Inputs::Elasticsearch
