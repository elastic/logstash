require "logstash/namespace"
require "logstash/outputs/base"
require "stud/buffer"

# This output lets you store logs in elasticsearch.
#
# This plugin uses the HTTP/REST interface to ElasticSearch, which usually
# lets you use any version of elasticsearch server. It is known to work
# with elasticsearch %ELASTICSEARCH_VERSION%
#
# You can learn more about elasticsearch at <http://elasticsearch.org>
class LogStash::Outputs::ElasticSearchHTTP < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "elasticsearch_http"
  milestone 2

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string

  # The hostname or ip address to reach your elasticsearch server.
  config :host, :validate => :string

  # The port for ElasticSearch HTTP interface to use.
  config :port, :validate => :number, :default => 9200

  # Set the number of events to queue up before writing to elasticsearch.
  #
  # If this value is set to 1, the normal ['index
  # api'](http://www.elasticsearch.org/guide/reference/api/index_.html).
  # Otherwise, the [bulk
  # api](http://www.elasticsearch.org/guide/reference/api/bulk.html) will
  # be used.
  config :flush_size, :validate => :number, :default => 100

  # The document ID for the index. Useful for overwriting existing entries in
  # elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # The amount of time since last flush before a flush is forced.
  config :idle_flush_time, :validate => :number, :default => 1

  public
  def register
    require "ftw" # gem ftw
    @agent = FTW::Agent.new
    @queue = []

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  public
  def receive(event)
    return unless output?(event)
    index = event.sprintf(@index)
    if @index_type.nil?
      type = "logs"
    else
      type = event.sprintf(@index_type)
    end
    buffer_receive(event, [index, type])
  end # def receive

  def flush(events, key, teardown=false)
    @logger.debug? && @logger.debug("Flushing events to elasticsearch",
                                    :count => events.count)
    index, type = key

    body = events.collect do |event|
      header = { "index" => { "_index" => index, "_type" => type } }
      header["index"]["_id"] = event.sprintf(@document_id) if !@document_id.nil?
      # Generate the body of the bulk request w/ a trailing newline.
      # http://www.elasticsearch.org/guide/reference/api/bulk.html
      #  "NOTE: the final line of data must end with a newline character \n."
      [ header, event ]
    end.flatten.collect(&:to_json).join("\n") + "\n"

    post(body)
  end # def receive_bulk

  def post(body)
    begin
      response = @agent.post!("http://#{@host}:#{@port}/_bulk", :body => body)
    rescue EOFError
      @logger.warn("EOF while writing request or reading response header from elasticsearch",
                   :host => @host, :port => @port)
      return # abort this flush
    end

    # Consume the body for error checking
    # This will also free up the connection for reuse.
    body = ""
    begin
      response.read_body { |chunk| body += chunk }
    rescue EOFError
      @logger.warn("EOF while reading response body from elasticsearch",
                   :host => @host, :port => @port)
      return # abort this flush
    end

    if response.status != 200
      @logger.error("Error writing (bulk) to elasticsearch",
                    :response => response, :response_body => body,
                    :request_body => @queue.join("\n"))
      return
    end
  end # def post

  def teardown
    buffer_flush(:final => true)
  end # def teardown
end # class LogStash::Outputs::ElasticSearchHTTP
