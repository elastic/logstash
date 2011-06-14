require "logstash/namespace"
require "logstash/outputs/base"

# This output lets you store logs in elasticsearch and is the most recommended
# output for logstash. If you plan on using the logstash web interface, you'll
# need to use this output.
#
#   *NOTE*: You must use the same version of elasticsearch server that logstash
#   uses for it's client. Currently we use elasticsearch 0.16.0
#
# You can learn more about elasticseasrch at <http://elasticsearch.org>
class LogStash::Outputs::Elasticsearch < LogStash::Outputs::Base

  # http://host/index/type
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

    gem "jruby-elasticsearch", ">= 0.0.3"
    require "jruby-elasticsearch"

    @logger.info(:message => "New ElasticSearch output", :cluster => @cluster,
                 :host => @host, :port => @port, :embedded => @embedded)
    @pending = []
    @callback = self.method(:receive_native)
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
  end # def register

  protected
  def start_local_elasticsearch
    @logger.info("Starting embedded ElasticSearch local node.")
    builder = org.elasticsearch.node.NodeBuilder.nodeBuilder
    builder.local(true)
    @embedded_elasticsearch = builder.node
    @embedded_elasticsearch.start
  end # def start_local_elasticsearch

  # TODO(sissel): Needs migration to  jrubyland
  public
  def ready(params)
    case params["method"]
    when "http"
      @logger.debug "ElasticSearch using http with URL #{@url.to_s}"
      #@http = EventMachine::HttpRequest.new(@url.to_s)
      @callback = self.method(:receive_http)
    when "river"
      require "logstash/outputs/amqp"
      params["port"] ||= 5672
      auth = "#{params["user"] or "guest"}:#{params["pass"] or "guest"}"
      mq_url = URI::parse("amqp://#{auth}@#{params["host"]}:#{params["port"]}/queue/#{params["queue"]}?durable=1")
      @mq = LogStash::Outputs::Amqp.new(mq_url.to_s)
      @mq.register
      @callback = self.method(:receive_river)
      em_url = URI.parse("http://#{@url.host}:#{@url.port}/_river/logstash#{@url.path.tr("/", "_")}/_meta")
      unused, @es_index, @es_type = @url.path.split("/", 3)

      river_config = {"type" => params["type"],
                      params["type"] => {"host" => params["host"],
                                         "user" => params["user"],
                                         "port" => params["port"],
                                         "pass" => params["pass"],
                                         "vhost" => params["vhost"],
                                         "queue" => params["queue"],
                                         "exchange" => params["queue"],
                                        },
                     "index" => {"bulk_size" => 100,
                                 "bulk_timeout" => "10ms",
                                },
                     }
      @logger.debug(["ElasticSearch using river", river_config])
      #http_setup = EventMachine::HttpRequest.new(em_url.to_s)
      req = http_setup.put :body => river_config.to_json
      req.errback do
        @logger.warn "Error setting up river: #{req.response}"
      end
      @callback = self.method(:receive_river)
    else raise "unknown elasticsearch method #{params["method"].inspect}"
    end

    #receive(LogStash::Event.new({
      #"@source" => "@logstashinit",
      #"@type" => "@none",
      #"@message" => "Starting logstash output to elasticsearch",
      #"@fields" => {
        #"HOSTNAME" => Socket.gethostname
      #},
    #}))

    pending = @pending
    @pending = []
    @logger.info("Flushing #{pending.size} events")
    pending.each do |event|
      receive(event)
    end
  end # def ready

  public
  def receive(event)
    if @callback
      @callback.call(event)
    else
      @pending << event
    end
  end # def receive

  public
  def receive_http(event, tries=5)
    req = @http.post :body => event.to_json
    req.errback do
      @logger.warn("Request to index to #{@url.to_s} failed (will retry, #{tries} tries left). Event was #{event.to_s}")
      EventMachine::add_timer(2) do
        # TODO(sissel): Actually abort if we retry too many times.
        receive_http(event, tries - 1)
      end
    end
  end # def receive_http

  public
  def receive_native(event)
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
  end # def receive_native

  public
  def receive_river(event)
    # bulk format; see http://www.elasticsearch.com/docs/elasticsearch/river/rabbitmq/
    index_message = {"index" => {"_index" => @es_index, "_type" => @es_type}}.to_json + "\n"
    #index_message += {@es_type => event.to_hash}.to_json + "\n"
    index_message += event.to_hash.to_json + "\n"
    @mq.receive_raw(index_message)
  end # def receive_river

  private
  def old_create_index
    # TODO(sissel): this is leftover from the old eventmachine days
    # make sure we don't need it, or, convert it.

    # Describe this index to elasticsearch
    indexmap = {
      # The name of the index
      "settings" => { 
        @url.path.split("/")[-1] => {
          "mappings" => {
            "@source" => { "type" => "string" },
            "@source_host" => { "type" => "string" },
            "@source_path" => { "type" => "string" },
            "@timestamp" => { "type" => "date" },
            "@tags" => { "type" => "string" },
            "@message" => { "type" => "string" },

            # TODO(sissel): Hack for now until this bug is resolved:
            # https://github.com/elasticsearch/elasticsearch/issues/issue/604
            "@fields" => { 
              "type" => "object",
              "properties" => {
                "HOSTNAME" => { "type" => "string" },
              },
            }, # "@fields"
          }, # "properties"
        }, # index map for this index type.
      }, # "settings"
    } # ES Index

    #indexurl = @esurl.to_s
    #indexmap_http = EventMachine::HttpRequest.new(indexurl)
    #indexmap_req = indexmap_http.put :body => indexmap.to_json
    #indexmap_req.callback do
      #@logger.info(["Done configuring index", indexurl, indexmap])
      #ready(params)
    #end
    #indexmap_req.errback do
      #@logger.warn(["Failure configuring index (http failed to connect?)",
                    #@esurl.to_s, indexmap])
      #@logger.warn([indexmap_req])
      ##sleep 30
      #raise "Failure configuring index: #{@esurl.to_s}"
      #
    #end
  end # def old_create_index
end # class LogStash::Outputs::Elasticsearch
