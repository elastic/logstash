require "logstash/namespace"
require "logstash/outputs/base"

# This output lets you store logs in elasticsearch and is the most recommended
# output for logstash. If you plan on using the logstash web interface, you'll
# need to use this output.
#
#   *NOTE*: You must use the same version of elasticsearch server that logstash
#   uses for its client. Currently we use elasticsearch 0.18.7
#
# You can learn more about elasticsearch at <http://elasticsearch.org>
class LogStash::Outputs::ElasticSearchHTTP < LogStash::Outputs::Base

  config_name "elasticsearch_http"
  plugin_status "experimental"

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

  # Run the elasticsearch server embedded in this process.
  # This option is useful if you want to run a single logstash process that
  # handles log processing and indexing; it saves you from needing to run
  # a separate elasticsearch process.
  config :embedded, :validate => :boolean, :default => false

  # If you are running the embedded elasticsearch server, you can set the http
  # port it listens on here; it is not common to need this setting changed from
  # default.
  config :embedded_http_port, :validate => :string, :default => "9200-9300"

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
    # TODO(sissel): find a better way of declaring where the elasticsearch
    # libraries are
    # TODO(sissel): can skip this step if we're running from a jar.
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/**/*.jar")
    Dir[jarpath].each do |jar|
        require jar
    end

    # setup log4j properties for elasticsearch
    @logger.setup_log4j

    if @embedded
      # Check for settings that are incompatible with @embedded
      %w(host).each do |name|
        if instance_variable_get("@#{name}")
          @logger.error("outputs/elasticsearch: You cannot specify " \
                        "'embedded => true' and also set '#{name}'")
          raise "Invalid configuration detected. Please fix."
        end
        # Force localhost for embedded elasticsearch
        @host = "localhost"
      end

      # Start elasticsearch local.
      start_local_elasticsearch
    end

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

  protected
  def start_local_elasticsearch
    @logger.info("Starting embedded ElasticSearch local node.")
    builder = org.elasticsearch.node.NodeBuilder.nodeBuilder
    # Disable 'local only' - LOGSTASH-277
    #builder.local(true)
    builder.settings.put("cluster.name", @cluster) if !@cluster.nil?
    builder.settings.put("http.port", @embedded_http_port)

    @embedded_elasticsearch = builder.node
    @embedded_elasticsearch.start
  end # def start_local_elasticsearch

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
    response = @agent.post!("http://#{@host}:#{@port}/#{index}/#{type}",
                            :body => event.to_json)
    # We must read the body to free up this connection for reuse.
    body = "";
    response.read_body { |chunk| body += chunk }

    if response.status != 201
      @logger.error("Error writing to elasticsearch",
                    :response => response, :response_body => body)
    end
  end # def receive_single

  def receive_bulk(event, index, type)
    @queue << [
      { "index" => { "_index" => index, "_type" => type } }.to_json,
      event.to_json
    ].join("\n")
    
    if @queue.size > @flush_size
      response = @agent.post!("http://#{@host}:#{@port}/_bulk",
                              :body => @queue.join("\n"))
      @queue.clear

      # We must read the body to free up this connection for reuse.
      body = "";
      response.read_body { |chunk| body += chunk }

      #if response.status != 201
      if response.status != 200
        @logger.error("Error writing (bulk) to elasticsearch",
                      :response => response, :response_body => body)
      end
    end
  end # def receive_bulk
end # class LogStash::Outputs::Elasticsearch
