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
class LogStash::Inputs::Elasticsearch < LogStash::Inputs::Base
  config_name "elasticsearch"
  milestone 1

  default :codec, "json"

  # The address of your elasticsearch server
  config :host, :validate => :string, :required => true

  # The http port of your elasticsearch server's REST interface
  config :port, :validate => :number, :default => 9200

  # The index to search
  config :index, :validate => :string, :default => "logstash-*"

  # The query to use
  config :query, :validate => :string, :default => "*"

  # Enable the scan search_type.
  # This will disable sorting but increase speed and performance.
  config :scan, :validate => :boolean, :default => true

  # This allows you to set the number of items you get back per scroll
  config :size, :validate => :number, :default => 1000

  # this parameter controls the keep alive time of the scrolling request and initiates the scrolling process.
  # The timeout applies per round trip (i.e. between the previous scan scroll request, to the next).
  config :scroll, :validate => :string, :default => "1m"

  # If true, the event will include meta data of the original elastic document: index ('_index') , document ('_type') and document id ('_id'). By default storted in an 'es_meta' field.
  # This metadata can be used to in reindexing scenarios to update rather than append existing indices 
  #
  # Example
  #      input {
  #        elasticsearch {
  #           host => "es.production.mysite.org"
  #           index => "mydata-2018.09.*"
  #           query => "*"
  #           size => 500
  #           scroll => "5m"
  #           include_meta => true
  #           meta_field => "es_orig"
  #        }
  #      }
  #      output {
  #        elasticsearch_http {
  #          host => "localhost"
  #          index => "copy-of-production.%{[es_orig][_index]}"
  #          index_type => "%{[es_orig][_type]}"
  #          document_id => "%{[es_orig][_id]}"
  #        }
  #      }
  # ( TODO : make the list of metadata fields configurable (?document version field)  )
  # ( TODO : elasticsearch output might need to use the bulk/create API instead
  #          of bulk/index API to avoid overwriting existing documents in the target index (idempotency)
  #          This is not yet supported in the elasticsearch outputs )
  # ( TODO : this solution stores the metadata as normal data on the target index. 
  #          consider alternative approach: include_meta will take the 'hit' document (including metadata) 
  #          and configure a custom output codec for elastic to index only the '_source' field )
  config :include_meta, :validate=> :boolean, :default => false
  
  # The (fixed) field name under which metadata of the original elastic document is stored
  # ( TODO : should this be a dynamic sprintf field ?) 
  config :meta_field, :validate=> :string, :default => "es_meta"

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

    @logger.debug("scroll initialization",:request => @url)
    # Execute the search request
    response = @agent.get!(@url)
    json = ""
    response.read_body { |c| json << c }
    result = JSON.parse(json)
    scroll_url = @url

    # When using the search_type=scan we don't get an initial result set.
    # So we do it here.
    if @scan and not result.nil? and not result["_scroll_id"].nil?    
      scroll_id = result["_scroll_id"]
      scroll_params = {
        "scroll_id" => scroll_id,
        "scroll" => @scroll
      }

      scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode(scroll_params)}"
      @logger.debug("initial scan",:request => scroll_url)
      
      response = @agent.get!(scroll_url)
      json = ""
      response.read_body { |c| json << c }
      result = JSON.parse(json)

    end

    while true
      break if result.nil?
      if result["error"]
        @logger.warn(result["error"], :request => scroll_url)
        break
      end
      
      hits = result["hits"]["hits"]
      break if hits.empty?

      hits.each do |hit|
        event = hit["_source"]
        if @include_meta 
           event[@meta_field] = { 
               '_index' => hit['_index'],
               '_type' => hit['_type'],
               '_id' => hit['_id']
           }
        end
        # Hack to make codecs work
        @codec.decode(event.to_json) do |event|
          decorate(event)
          output_queue << event
        end
      end

      # Get the scroll id from the previous result set and use it for getting the next data set
      scroll_id = result["_scroll_id"]
      if scroll_id.nil?
         @logger.warn("no _scroll_id in result", :request => scroll_url)
         break 
      end

      # Fetch the next result set
      scroll_params = {
        "scroll_id" => scroll_id,
        "scroll" => @scroll
      }
      scroll_url = "http://#{@host}:#{@port}/_search/scroll?#{encode(scroll_params)}"
      @logger.debug("scroll request",:request => scroll_url)
      response = @agent.get!(scroll_url)
      json = ""
      response.read_body { |c| json << c }
      result = JSON.parse(json)
    end
  rescue LogStash::ShutdownSignal
    # Do nothing, let us quit.
  end # def run
end # class LogStash::Inputs::Elasticsearch
