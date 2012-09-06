require "logstash/namespace"
require "logstash/outputs/base"

# This output lets you store logs in elasticsearch and is the most recommended
# output for logstash. If you plan on using the logstash web interface, you'll
# need to use this output.
#
#   *NOTE*: The elasticsearch client is version 0.19.8. Your elasticsearch
#   cluster must be running 0.19.x for API compatibility.
#
# You can learn more about elasticsearch at <http://elasticsearch.org>
class LogStash::Outputs::ElasticSearchHTTP < LogStash::Outputs::Base

  config_name "elasticsearch_http"
  plugin_status "beta"

  # ElasticSearch server name. This is optional if your server is discoverable.
  config :host, :validate => :string

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string, :default => "%{@type}"

  # The name of your cluster if you set it on the ElasticSearch side. Useful
  # for discovery.
  config :cluster, :validate => :string

  # The name/address of the host to use for ElasticSearch unicast discovery
  # This is only required if the normal multicast/cluster discovery stuff won't
  # work in your environment.
  config :host, :validate => :string

  # The port for ElasticSearch transport to use. This is *not* the ElasticSearch
  # REST API port (normally 9200).
  config :port, :validate => :number, :default => 9200

  # Set the number of events to queue up before writing to elasticsearch.
  #
  # If this value is set to 1, the normal ['index
  # api'](http://www.elasticsearch.org/guide/reference/api/index_.html).
  # Otherwise, the [bulk
  # api](http://www.elasticsearch.org/guide/reference/api/bulk.html) will
  # be used.
  config :flush_size, :validate => :number, :default => 100

  public
  def register
    require "ftw" # gem ftw
    @agent = FTW::Agent.new

    # TODO(sissel): Implement this model in FTW:
    #    reader, writer = IO.pipe
    #    request = agent.post(url, :body => reader)
    #    agent.execute(request)
    #    writer.write(body...)
    #    writer.write(body...)
    #    writer.write(body...)
    #    writer.close
    #    TODO(sissel): How to get the response?
    @queue = []
  end # def register

  public
  def receive(event)
    return unless output?(event)

    index = event.sprintf(@index)
    type = event.sprintf(@index_type)
    # TODO(sissel): allow specifying the ID?
    # The document ID is how elasticsearch determines sharding hash, so it can
    # help performance if we allow folks to specify a specific ID.

    if @flush_size == 1
      receive_single(event, index, type)
    else
      receive_bulk(event, index, type)
    end # 
  end # def receive

  def receive_single(event, index, type)
    begin
      response = @agent.post!("http://#{@host}:#{@port}/#{index}/#{type}",
                              :body => event.to_json)
      # We must read the body to free up this connection for reuse.
      body = "";
      response.read_body { |chunk| body += chunk }

      if response.status != 201
        @logger.error("Error writing to elasticsearch",
                      :response => response, :response_body => body)
        retry
      end
    end
  end # def receive_single

  def receive_bulk(event, index, type)
    @queue << [
      { "index" => { "_index" => index, "_type" => type } }.to_json,
      event.to_json
    ].join("\n")

    # Keep trying to flush while the queue is full.
    # This will cause retries in flushing if the flush fails.
    flush while @queue.size >= @flush_size
  end # def receive_bulk

  def flush
    puts "Flushing #{@queue.count} events"
    # If we don't tack a trailing newline at the end, elasticsearch
    # doesn't seem to process the last event in this bulk index call.
    response = @agent.post!("http://#{@host}:#{@port}/_bulk",
                            :body => @queue.join("\n") + "\n")

    # Consume the body for error checking
    # This will also free up the connection for reuse.
    body = ""
    response.read_body { |chunk| body += chunk }

    if response.status != 200
      @logger.error("Error writing (bulk) to elasticsearch",
                    :response => response, :response_body => body,
                    :request_body => @queue.join("\n"))
      return
    end
    @queue.clear
  end # def flush

  def teardown
    flush while @queue.size > 0
  end # def teardown
end # class LogStash::Outputs::ElasticSearchHTTP
