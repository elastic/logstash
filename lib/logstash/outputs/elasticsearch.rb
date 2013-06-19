require "logstash/namespace"
require "logstash/outputs/base"
require "stud/buffer"

# This output lets you store logs in elasticsearch and is the most recommended
# output for logstash. If you plan on using the logstash web interface, you'll
# need to use this output.
#
#   *VERSION NOTE*: Your elasticsearch cluster must be running elasticsearch
#   %ELASTICSEARCH_VERSION%. If you use any other version of elasticsearch,
#   you should consider using the [elasticsearch_http](elasticsearch_http)
#   output instead.
#
# If you want to set other elasticsearch options that are not exposed directly
# as config options, there are two options:
#
# * create an elasticsearch.yml file in the $PWD of the logstash process
# * pass in es.* java properties (java -Des.node.foo= or ruby -J-Des.node.foo=)
#
# This plugin will join your elasticsearch cluster, so it will show up in
# elasticsearch's cluster health status.
#
# You can learn more about elasticsearch at <http://elasticsearch.org>
#
# ## Operational Notes
#
# Your firewalls will need to permit port 9300 in *both* directions (from
# logstash to elasticsearch, and elasticsearch to logstash)
class LogStash::Outputs::ElasticSearch < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "elasticsearch"
  milestone 3

  # ElasticSearch server name. This is optional if your server is discoverable.
  config :host, :validate => :string

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string

  # The document ID for the index. Useful for overwriting existing entries in
  # elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # The name of your cluster if you set it on the ElasticSearch side. Useful
  # for discovery.
  config :cluster, :validate => :string

  # The name/address of the host to use for ElasticSearch unicast discovery
  # This is only required if the normal multicast/cluster discovery stuff won't
  # work in your environment.
  config :host, :validate => :string

  # The port for ElasticSearch transport to use. This is *not* the ElasticSearch
  # REST API port (normally 9200).
  config :port, :validate => :string, :default => "9300-9400"

  # The name/address of the host to bind to for ElasticSearch clustering
  config :bind_host, :validate => :string

  # Run the elasticsearch server embedded in this process.
  # This option is useful if you want to run a single logstash process that
  # handles log processing and indexing; it saves you from needing to run
  # a separate elasticsearch process.
  config :embedded, :validate => :boolean, :default => false

  # If you are running the embedded elasticsearch server, you can set the http
  # port it listens on here; it is not common to need this setting changed from
  # default.
  config :embedded_http_port, :validate => :string, :default => "9200-9300"

  # This setting no longer does anything. It exists to keep config validation
  # from failing. It will be removed in future versions.
  config :max_inflight_requests, :validate => :number, :default => 50, :deprecated => true

  # The node name ES will use when joining a cluster.
  #
  # By default, this is generated internally by the ES client.
  config :node_name, :validate => :string

  # The maximum number of events to spool before flushing to elasticsearch.
  config :flush_size, :validate => :number, :default => 100

  # The amount of time since last flush before a flush is forced.
  config :idle_flush_time, :validate => :number, :default => 1

  public
  def register
    # TODO(sissel): find a better way of declaring where the elasticsearch
    # libraries are
    # TODO(sissel): can skip this step if we're running from a jar.
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/elasticsearch*/lib/*.jar")
    Dir[jarpath].each do |jar|
      require jar
    end

    # setup log4j properties for elasticsearch
    LogStash::Logger.setup_log4j(@logger)

    if @embedded
      # Default @host with embedded to localhost. This should help avoid
      # newbies tripping on ubuntu and other distros that have a default
      # firewall that blocks multicast.
      @host ||= "localhost"

      # Start elasticsearch local.
      start_local_elasticsearch
    end
    require "jruby-elasticsearch"

    @logger.info("New ElasticSearch output", :cluster => @cluster,
                 :host => @host, :port => @port, :embedded => @embedded)
    options = {
      :cluster => @cluster,
      :host => @host,
      :port => @port,
      :bind_host => @bind_host,
      :node_name => @node_name,
    }

    # TODO(sissel): Support 'transport client'
    options[:type] = :node

    @client = ElasticSearch::Client.new(options)
    # TODO(sissel): Set up the bulkstream.

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  protected
  def start_local_elasticsearch
    @logger.info("Starting embedded ElasticSearch local node.")
    builder = org.elasticsearch.node.NodeBuilder.nodeBuilder
    # Disable 'local only' - LOGSTASH-277
    #builder.local(true)
    builder.settings.put("cluster.name", @cluster) if !@cluster.nil?
    builder.settings.put("node.name", @node_name) if !@node_name.nil?
    builder.settings.put("http.port", @embedded_http_port)

    @embedded_elasticsearch = builder.node
    @embedded_elasticsearch.start
  end # def start_local_elasticsearch

  public
  def receive(event)
    return unless output?(event)
    buffer_receive([event, index, type])
  end # def receive

  def flush(events, teardown=false)
    request = @client.bulk
    events.each do |event, index, type|
      index = event.sprintf(@index)

      # Set the 'type' value for the index.
      if @index_type.nil?
        type =  event["type"] || "logs"
      else
        type = event.sprintf(@index_type)
      end

      if @document_id
        request.index(index, type, event.sprintf(@document_id), event.to_json)
      else
        request.index(index, type, nil, event.to_json)
      end
    end

    request.on(:success) { }
    request.execute
  end # def flush

end # class LogStash::Outputs::Elasticsearch
