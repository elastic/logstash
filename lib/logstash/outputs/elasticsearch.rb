# encoding: utf-8
require "logstash/namespace"
require "logstash/environment"
require "logstash/outputs/base"
require "logstash/json"
require "stud/buffer"
require "socket" # for Socket.gethostname

# This output lets you store logs in Elasticsearch and is the most recommended
# output for Logstash. If you plan on using the Kibana web interface, you'll
# need to use this output.
#
#   *VERSION NOTE*: Your Elasticsearch cluster must be running Elasticsearch
#   %ELASTICSEARCH_VERSION%. If you use any other version of Elasticsearch,
#   you should set `protocol => http` in this plugin.
#
# If you want to set other Elasticsearch options that are not exposed directly
# as configuration options, there are two methods:
#
# * Create an `elasticsearch.yml` file in the $PWD of the Logstash process
# * Pass in es.* java properties (java -Des.node.foo= or ruby -J-Des.node.foo=)
#
# With the default `protocol` setting ("node"), this plugin will join your
# Elasticsearch cluster as a client node, so it will show up in Elasticsearch's
# cluster status.
#
# You can learn more about Elasticsearch at <http://www.elasticsearch.org>
#
# ## Operational Notes
#
# Template management requires Elasticsearch version 0.90.7 or later. If you
# are using a version older than this, please upgrade. You will receive
# more benefits than just template management!
#
# If using the default `protocol` setting ("node"), your firewalls might need
# to permit port 9300 in *both* directions (from Logstash to Elasticsearch, and
# Elasticsearch to Logstash)
class LogStash::Outputs::ElasticSearch < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "elasticsearch"
  milestone 3

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  # Indexes may not contain uppercase characters.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string

  # Starting in Logstash 1.3 (unless you set option "manage_template" to false)
  # a default mapping template for Elasticsearch will be applied, if you do not
  # already have one set to match the index pattern defined (default of
  # "logstash-%{+YYYY.MM.dd}"), minus any variables.  For example, in this case
  # the template will be applied to all indices starting with logstash-*
  #
  # If you have dynamic templating (e.g. creating indices based on field names)
  # then you should set "manage_template" to false and use the REST API to upload
  # your templates manually.
  config :manage_template, :validate => :boolean, :default => true

  # This configuration option defines how the template is named inside Elasticsearch.
  # Note that if you have used the template management features and subsequently
  # change this, you will need to prune the old template manually, e.g.
  # curl -XDELETE <http://localhost:9200/_template/OldTemplateName?pretty>
  # where OldTemplateName is whatever the former setting was.
  config :template_name, :validate => :string, :default => "logstash"

  # You can set the path to your own template here, if you so desire.
  # If not set, the included template will be used.
  config :template, :validate => :path

  # Overwrite the current template with whatever is configured
  # in the template and template_name directives.
  config :template_overwrite, :validate => :boolean, :default => false

  # The document ID for the index. Useful for overwriting existing entries in
  # Elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # The name of your cluster if you set it on the Elasticsearch side. Useful
  # for discovery.
  config :cluster, :validate => :string

  # The hostname or IP address of the host to use for Elasticsearch unicast discovery
  # This is only required if the normal multicast/cluster discovery stuff won't
  # work in your environment.
  config :host, :validate => :string

  # The port for Elasticsearch transport to use.
  #
  # If you do not set this, the following defaults are used:
  # * `protocol => http` - port 9200
  # * `protocol => transport` - port 9300-9305
  # * `protocol => node` - port 9300-9305
  config :port, :validate => :string

  # The name/address of the host to bind to for Elasticsearch clustering
  config :bind_host, :validate => :string

  # This is only valid for the 'node' protocol.
  #
  # The port for the node to listen on.
  config :bind_port, :validate => :number

  # Run the Elasticsearch server embedded in this process.
  # This option is useful if you want to run a single Logstash process that
  # handles log processing and indexing; it saves you from needing to run
  # a separate Elasticsearch process.
  config :embedded, :validate => :boolean, :default => false

  # If you are running the embedded Elasticsearch server, you can set the http
  # port it listens on here; it is not common to need this setting changed from
  # default.
  config :embedded_http_port, :validate => :string, :default => "9200-9300"

  # This setting no longer does anything. It exists to keep config validation
  # from failing. It will be removed in future versions.
  config :max_inflight_requests, :validate => :number, :default => 50, :deprecated => true

  # The node name Elasticsearch will use when joining a cluster.
  #
  # By default, this is generated internally by the ES client.
  config :node_name, :validate => :string

  # This plugin uses the bulk index api for improved indexing performance.
  # To make efficient bulk api calls, we will buffer a certain number of
  # events before flushing that out to Elasticsearch. This setting
  # controls how many events will be buffered before sending a batch
  # of events.
  config :flush_size, :validate => :number, :default => 5000

  # The amount of time since last flush before a flush is forced.
  #
  # This setting helps ensure slow event rates don't get stuck in Logstash.
  # For example, if your `flush_size` is 100, and you have received 10 events,
  # and it has been more than `idle_flush_time` seconds since the last flush,
  # Logstash will flush those 10 events automatically.
  #
  # This helps keep both fast and slow log streams moving along in
  # near-real-time.
  config :idle_flush_time, :validate => :number, :default => 1

  # Choose the protocol used to talk to Elasticsearch.
  #
  # The 'node' protocol will connect to the cluster as a normal Elasticsearch
  # node (but will not store data). This allows you to use things like
  # multicast discovery. If you use the `node` protocol, you must permit
  # bidirectional communication on the port 9300 (or whichever port you have
  # configured).
  #
  # The 'transport' protocol will connect to the host you specify and will
  # not show up as a 'node' in the Elasticsearch cluster. This is useful
  # in situations where you cannot permit connections outbound from the
  # Elasticsearch cluster to this Logstash server.
  #
  # The 'http' protocol will use the Elasticsearch REST/HTTP interface to talk
  # to elasticsearch.
  #
  # All protocols will use bulk requests when talking to Elasticsearch.
  #
  # The default `protocol` setting under java/jruby is "node". The default
  # `protocol` on non-java rubies is "http"
  config :protocol, :validate => [ "node", "transport", "http" ]

  # The Elasticsearch action to perform. Valid actions are: `index`, `delete`.
  #
  # Use of this setting *REQUIRES* you also configure the `document_id` setting
  # because `delete` actions all require a document id.
  #
  # What does each action do?
  #
  # - index: indexes a document (an event from logstash).
  # - delete: deletes a document by id
  #
  # For more details on actions, check out the [Elasticsearch bulk API documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/docs-bulk.html)
  config :action, :validate => :string, :default => "index"

  public
  def register
    client_settings = {}
    client_settings["cluster.name"] = @cluster if @cluster
    client_settings["network.host"] = @bind_host if @bind_host
    client_settings["transport.tcp.port"] = @bind_port if @bind_port

    if @node_name
      client_settings["node.name"] = @node_name
    else
      client_settings["node.name"] = "logstash-#{Socket.gethostname}-#{$$}-#{object_id}"
    end

    if @protocol.nil?
      @protocol = LogStash::Environment.jruby? ? "node" : "http"
    end

    if ["node", "transport"].include?(@protocol)
      # Node or TransportClient; requires JRuby
      raise(LogStash::PluginLoadingError, "This configuration requires JRuby. If you are not using JRuby, you must set 'protocol' to 'http'. For example: output { elasticsearch { protocol => \"http\" } }") unless LogStash::Environment.jruby?
      LogStash::Environment.load_elasticsearch_jars!

      # setup log4j properties for Elasticsearch
      LogStash::Logger.setup_log4j(@logger)
    end

    require "logstash/outputs/elasticsearch/protocol"

    if @port.nil?
      @port = case @protocol
        when "http"; "9200"
        when "transport", "node"; "9300-9305"
      end
    end

    if @host.nil? && @protocol == "http"
      @logger.info("No 'host' set in elasticsearch output. Defaulting to localhost")
      @host = "localhost"
    end

    options = {
      :host => @host,
      :port => @port,
      :client_settings => client_settings
    }


    client_class = case @protocol
      when "transport"
        LogStash::Outputs::Elasticsearch::Protocols::TransportClient
      when "node"
        LogStash::Outputs::Elasticsearch::Protocols::NodeClient
      when "http"
        LogStash::Outputs::Elasticsearch::Protocols::HTTPClient
    end

    if @embedded
      raise(LogStash::ConfigurationError, "The 'embedded => true' setting is only valid for the elasticsearch output under JRuby. You are running #{RUBY_DESCRIPTION}") unless LogStash::Environment.jruby?
      LogStash::Environment.load_elasticsearch_jars!

      # Default @host with embedded to localhost. This should help avoid
      # newbies tripping on ubuntu and other distros that have a default
      # firewall that blocks multicast.
      @host ||= "localhost"

      # Start Elasticsearch local.
      start_local_elasticsearch
    end

    @client = client_class.new(options)

    @logger.info("New Elasticsearch output", :cluster => @cluster,
                 :host => @host, :port => @port, :embedded => @embedded,
                 :protocol => @protocol)


    if @manage_template
      @logger.info("Automatic template management enabled", :manage_template => @manage_template.to_s)
      @client.template_install(@template_name, get_template, @template_overwrite)
    end # if @manage_templates

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  public
  def get_template
    if @template.nil?
      @template = LogStash::Environment.plugin_path("outputs/elasticsearch/elasticsearch-template.json")
      if !File.exists?(@template)
        raise "You must specify 'template => ...' in your elasticsearch output (I looked for '#{@template}')"
      end
    end
    template_json = IO.read(@template).gsub(/\n/,'')
    @logger.info("Using mapping template", :template => template_json)
    return LogStash::Json.load(template_json)
  end # def get_template

  protected
  def start_local_elasticsearch
    @logger.info("Starting embedded Elasticsearch local node.")
    builder = org.elasticsearch.node.NodeBuilder.nodeBuilder
    # Disable 'local only' - LOGSTASH-277
    #builder.local(true)
    builder.settings.put("cluster.name", @cluster) if @cluster
    builder.settings.put("node.name", @node_name) if @node_name
    builder.settings.put("network.host", @bind_host) if @bind_host
    builder.settings.put("http.port", @embedded_http_port)

    @embedded_elasticsearch = builder.node
    @embedded_elasticsearch.start
  end # def start_local_elasticsearch

  public
  def receive(event)
    return unless output?(event)

    # Set the 'type' value for the index.
    if @index_type
      type = event.sprintf(@index_type)
    else
      type = event["type"] || "logs"
    end

    index = event.sprintf(@index)

    document_id = @document_id ? event.sprintf(@document_id) : nil
    buffer_receive([event.sprintf(@action), { :_id => document_id, :_index => index, :_type => type }, event.to_hash])
  end # def receive

  def flush(actions, teardown=false)
    @client.bulk(actions)
    # TODO(sissel): Handle errors. Since bulk requests could mostly succeed
    # (aka partially fail), we need to figure out what documents need to be
    # retried.
    #
    # In the worst case, a failing flush (exception) will incur a retry from Stud::Buffer.
  end # def flush

  def teardown
    buffer_flush(:final => true)
  end

end # class LogStash::Outputs::Elasticsearch
