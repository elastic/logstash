require "thread"
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

  # The number of log events to store in memory before blocking
  # Set to larger numbers for better performance. In the event of a crash,
  # all buffered events will be lost.
  config :buffer_size, :validate => :number, :default => 1

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

    # Create a separate thread to do the flushing
    @event_buffer = SizedQueue.new(@buffer_size) # events to send
    @shutdown_requested = false
    @elasticsearch_writer = Thread.new do
      while !@shutdown_requested
        begin
          wait_and_flush_buffer
        rescue Exception => e
          @logger.error(["Failed to send events to ElasticSearch", e, e.backtrace])
        end
      end
      wait_and_flush_buffer if @event_buffer.length > 0 # Final flush
    end
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
    @event_buffer << event
  end

  # Make a blocking call to get at least one event, and then get the rest.
  # Send them all to ElasticSearch
  protected
  def wait_and_flush_buffer
    bulk_request = @client.bulk
    num_events = add_index_request(bulk_request, @event_buffer.pop) # blocking

    # Send up to the @buffer_size events at once
    while @event_buffer.length > 0 && num_events < @buffer_size
      num_events += add_index_request(bulk_request, @event_buffer.pop)
    end

    return if num_events <= 0

    bulk_request.on(:success) do |response|
      @logger.debug("Index successful")
    end.on(:failure) do |exception|
      @logger.warn(["Failed to index an event", exception])
    end

    @logger.debug(["Sending bulk index request", {:num_events => num_events}])
    bulk_request.execute! # synchronously
  end

  # Returns number of events added
  protected
  def add_index_request(bulk_request, event)
    return 0 if event.nil?
    @logger.debug(["Adding event to bulk index request", event.to_hash])
    index = event.sprintf(@index)
    type = event.sprintf(@type)

    # TODO(sissel): allow specifying the ID?
    # The document ID is how elasticsearch determines sharding hash, so it can
    # help performance if we allow folks to specify a specific ID.
    bulk_request.index(index, type, nil, event.to_hash)
    return 1
  end

  public
  def teardown
    @shutdown_requested = true
    @event_buffer << nil # Send a final event to wake up the thread
    @logger.info("Waiting for elasticsearch writer to finish")

    # There may be a race condition which will cause the thread to wait forever.
    # Give it some time and then be aggressive.
    unless @elasticsearch_writer.join(10)
      @logger.info("Time's up; killing elasticsearch writer")
      @elasticsearch_writer.kill
    end
    finished
  end

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
