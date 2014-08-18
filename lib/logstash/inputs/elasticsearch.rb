# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "logstash/json"

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

  # If set, include Elasticsearch document information such as index, type, and id in the event.
  # (`_index`, `_type`, and `_id` from the Elasticsearch API become `index`,
  # `type`, and `id` as field names)
  # 
  # This information can be used to in reindexing scenarios to update rather
  # than append existing indices
  #
  # Example
  #
  #     input {
  #       elasticsearch {
  #         host => "es.production.mysite.org"
  #         index => "mydata-2018.09.*"
  #         query => "*"
  #         size => 500
  #         scroll => "5m"
  #         docinfo_target => "es"
  #       }
  #     }
  #     output {
  #       elasticsearch {
  #         index => "copy-of-production.%{[es][index]}"
  #         index_type => "%{[es][type]}"
  #         document_id => "%{[es][id]}"
  #       }
  #     }
  config :docinfo_target, :validate=> :string

  public
  def register
    # ( TODO : make the list of metadata fields configurable (?document version field) )
    # ( TODO : elasticsearch output might need to use the bulk/create API instead
    # of bulk/index API to avoid overwriting existing documents in the target index (idempotency)
    # This is not yet supported in the elasticsearch outputs )
    # ( TODO : this solution stores the metadata as normal data on the target index.
    # consider alternative approach: include_meta will take the 'hit' document (including metadata)
    # and configure a custom output codec for elastic to index only the '_source' field )
    
    require "ftw"
    @agent = FTW::Agent.new

    params = {
      "q" => @query,
      "scroll" => @scroll,
      "size" => "#{@size}",
    }
    params['search_type'] = "scan" if @scan

    @search_url = "http://#{@host}:#{@port}/#{@index}/_search?#{encode(params)}"
    @scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode({"scroll" => @scroll})}"
  end # def register

  private
  def encode(hash)
    return hash.collect do |key, value|
      CGI.escape(key) + "=" + CGI.escape(value)
    end.join("&")
  end # def encode

  private
  def execute_search_request
    response = @agent.get!(@search_url)
    json = ""
    response.read_body { |c| json << c }
    json
  end

  private
  def execute_scroll_request(scroll_id)
    response = @agent.post!(@scroll_url, :body => scroll_id)
    json = ""
    response.read_body { |c| json << c }
    json
  end

  public
  def run(output_queue)
    result = LogStash::Json.load(execute_search_request)
    scroll_id = result["_scroll_id"]

    # When using the search_type=scan we don't get an initial result set.
    # So we do it here.
    if @scan
      result = LogStash::Json.load(execute_scroll_request(scroll_id))
    end

    loop do
      break if result.nil?
      hits = result["hits"]["hits"]
      break if hits.empty?

      hits.each do |hit|
        # Hack to make codecs work
        @codec.decode(LogStash::Json.dump(hit["_source"])) do |event|
          decorate(event)
          if @docinfo_target
            event[@docinfo_target] = {
              "index" => hit["_index"],
              "type" => hit["_type"],
              "id" => hit["_id"]
            }
          end
          output_queue << event
        end
      end

      # Get the scroll id from the previous result set and use it for getting the next data set
      scroll_id = result["_scroll_id"]

      # Fetch the next result set
      result = LogStash::Json.load(execute_scroll_request(scroll_id))

      if result["error"]
        @logger.warn(result["error"], :request => @scroll_url)
        # TODO(sissel): raise an error instead of breaking
        break
      end

    end
  rescue LogStash::ShutdownSignal
    # Do nothing, let us quit.
  end # def run
end # class LogStash::Inputs::Elasticsearch
