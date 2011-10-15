require "logstash/namespace"
require "logstash/outputs/base"

# This output lets you store logs in elasticsearch and is the most recommended
# output for logstash. If you plan on using the logstash web interface, you'll
# need to use this output.
#
#   *NOTE*: You must use the same version of elasticsearch server that logstash
#   uses for it's client. Currently we use elasticsearch 0.17.6
#
# You can learn more about elasticseasrch at <http://elasticsearch.org>
class LogStash::Outputs::ElasticSearch < LogStash::Outputs::Base

  config_name "elasticsearch"

  # ElasticSearch server name. This is optional if your server is discoverable.
  config :host, :validate => :string

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indeces by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The type to write events to. Generally you should try to write only similar
  # events to the same 'type'. String expansion '%{foo}' works here.
  config :type, :validate => :string, :default => "%{@type}"

  # The name of your cluster if you set it on the ElasticSearch side. Useful
  # for discovery.
  config :cluster, :validate => :string

  # The name/address of the host to use for ElasticSearch unicast discovery
  # This is only required if the normal multicast/cluster discovery stuff won't
  # work in your environment.
  config :host, :validate => :string

  # The port for ElasticSearch transport to use. This is *not* the ElasticSearch
  # REST API port (normally 9200).
  config :port, :validate => :number, :default => 9300

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

  # TODO(sissel): Config for river?

  public
  def register
    # TODO(sissel): find a better way of declaring where the elasticsearch
    # libraries are
    # TODO(sissel): can skip this step if we're running from a jar.
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/**/*.jar")
    Dir[jarpath].each do |jar|
        require jar
    end

    if @embedded
      %w(host cluster bind_host).each do |name|
        if instance_variable_get("@#{name}")
          @logger.error("outputs/elasticsearch: You cannot specify " \
                        "'embedded => true' and also set '#{name}'")
          raise "Invalid configuration detected. Please fix."
        end
      end

      # Start elasticsearch local.
      start_local_elasticsearch
    end

    require "jruby-elasticsearch"

    @logger.info(:message => "New ElasticSearch output", :cluster => @cluster,
                 :host => @host, :port => @port, :embedded => @embedded)
    @pending = []
    options = {
      :cluster => @cluster,
      :host => @host,
      :port => @port,
      :bind_host => @bind_host,
    }

    if (@embedded)
      options[:type] = :local
    else
      options[:type] = :node
      # TODO(sissel): Support 'transport client'
    end

    @client = ElasticSearch::Client.new(options)

    # TODO(sissel): Set up the bulkstream.
  end # def register

  protected
  def start_local_elasticsearch
    @logger.info("Starting embedded ElasticSearch local node.")
    builder = org.elasticsearch.node.NodeBuilder.nodeBuilder
    builder.local(true)
    builder.settings.put("http.port", @embedded_http_port)

    @embedded_elasticsearch = builder.node
    @embedded_elasticsearch.start
  end # def start_local_elasticsearch

  public
  def receive(event)
    index = event.sprintf(@index)
    type = event.sprintf(@type)
    # TODO(sissel): allow specifying the ID?
    # The document ID is how elasticsearch determines sharding hash, so it can
    # help performance if we allow folks to specify a specific ID.
    req = @client.index(index, type, event.to_hash)
    req.on(:success) do |response|
      @logger.debug(["Successfully indexed", event.to_hash])
    end.on(:failure) do |exception|
      @logger.debug(["Failed to index an event", exception, event.to_hash])
    end
    req.execute
  end # def receive
end # class LogStash::Outputs::Elasticsearch
