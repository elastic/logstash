# encoding: utf-8
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

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  # Indexes may not contain uppercase characters.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string

  # Starting in Logstash 1.3 (unless you set option "manage_template" to false) 
  # a default mapping template for Elasticsearch will be applied if you do not 
  # already have one set to match the index pattern defined (default of 
  # "logstash-%{+YYYY.MM.dd}"), minus any variables.  For example, in this case
  # the template will be applied to all indices starting with logstash-* 
  # If you have dynamic templating (e.g. creating indices based on field names)
  # then you should set "manage_template" to false and use the REST API to upload
  # your templates manually.
  # This configuration option defines how the template is named inside Elasticsearch
  config :template_name, :validate => :string, :default => "logstash_per_index"
  
  # You can set the path to your own template here, if you so desire.  
  # If not the included template will be used.
  config :template, :validate => :path
  
  # Overwrite the current template with whatever is configured 
  # in the template and template_name directives.
  config :template_overwrite, :validate => :boolean, :default => false
  
  # Logstash will install the default template unless it finds one pre-existing
  # or you have set this option to false.
  config :manage_template, :validate => :boolean, :default => true
  
  # This is for template management only!
  # The HTTP Basic Auth username used to access the elasticsearch server REST API
  config :username, :validate => :string, :default => nil

  # This is for template management only!
  # The HTTP Basic Auth password used to access the elasticsearch server REST API.
  config :password, :validate => :password, :default => nil
  
  # This is for template management only!
  # The HTTP port used to access the elasticsearch server REST API.
  config :template_port, :validate => :number, :default => 9200

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
  config :port, :validate => :string, :default => "9300-9305"

  # The name/address of the host to bind to for ElasticSearch clustering
  config :bind_host, :validate => :string

  # This is only valid for the 'node' protocol.
  #
  # The port for the node to listen on.
  config :bind_port, :validate => :number

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

  # Choose the protocol used to talk to elasticsearch.
  #
  # The 'node' protocol will connect to the cluster as a normal elasticsearch
  # node (but will not store data). This allows you to use things like
  # multicast discovery.
  #
  # The 'transport' protocol will connect to the host you specify and will
  # not show up as a 'node' in the elasticsearch cluster. This is useful
  # in situations where you cannot permit connections outbound from the
  # elasticsearch cluster to this logstash server.
  config :protocol, :validate => [ "node", "transport" ], :default => "node"

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

    # :node or :transport protocols
    options[:type] = @protocol.to_sym 

    options[:bind_port] = @bind_port unless @bind_port.nil?

    # TransportClient requires a number for a port.
    options[:port] = options[:port].to_i if options[:type] == :transport

    @client = ElasticSearch::Client.new(options)
    
    if @manage_template
      @logger.info("Automatic template configuration enabled", :manage_template => @manage_template.to_s)
      require "ftw" # gem ftw
      @agent = FTW::Agent.new
      auth = @username && @password ? "#{@username}:#{@password.value}@" : ""
      template_search_url = "http://#{auth}#{@host}:#{@template_port}/_template/*"
      @template_url = "http://#{auth}#{@host}:#{@template_port}/_template/#{@template_name}"
      if @template_overwrite
        @logger.info("Template overwrite enabled.  Deleting existing template.", :template_overwrite => @template_overwrite.to_s)
        response = @agent.get!(@template_url)
        template_action('delete') if response.status == 200 #=> Purge the old template if it exists
      end
      @logger.debug("Template Search URL:", :template_search_url => template_search_url)
      has_template = false
      template_idx_name = @index.sub(/%{[^}]+}/,'*')
      alt_template_idx_name = @index.sub(/-%{[^}]+}/,'*')
      # Get the template data
      response = @agent.get!(template_search_url)
      json = ""
      if response.status == 404 #=> This condition can occcur when no template has ever been appended
        @logger.info("No template found in Elasticsearch...")
        get_template_json
        template_action('put')
      elsif response.status == 200
        begin
          response.read_body { |c| json << c }
          results = JSON.parse(json)
        rescue Exception => e
          @logger.error("Error parsing JSON", :json => json, :results => results.to_s, :error => e.to_s)
          raise "Exception in parsing JSON", e
        end
        if !results.any? { |k,v| v["template"] == template_idx_name || v["template"] == alt_template_idx_name }
          @logger.debug("No template found in Elasticsearch", :has_template => has_template, :name => template_idx_name, :alt => alt_template_idx_name)
          get_template_json
          template_action('put')      
        end
      else #=> Some other status code?
        @logger.error("Could not check for existing template.  Check status code.", :status => response.status.to_s)
      end # end if response.status == 200
    end # end if @manage_template
    
    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  public 
  def template_action(command)
    begin
      if command == 'delete'
        response = @agent.delete!(@template_url)
        response.discard_body
      elsif command == 'put'
        response = @agent.put!(@template_url, :body => @template_json)
        response.discard_body
      end
    rescue EOFError
      @logger.warn("EOF while attempting request or reading response header from elasticsearch",
                   :host => @host, :port => @template_port)
      return # abort this action
    end
    if response.status != 200
      @logger.error("Error acting on elasticsearch mapping template",
                    :response => response, :action => command,
                    :request_url => @template_url)
      return
    end
    @logger.info("Successfully deleted template", :template_url => @template_url) if command == 'delete'
    @logger.info("Successfully applied template", :template_url => @template_url) if command == 'put'
  end # def template_action
  
  
  public
  def get_template_json
    if @template.nil?
      if __FILE__ =~ /^(jar:)?file:\/.+!.+/
        begin
          # Running from a jar, assume types.db is at the root.
          jar_path = [__FILE__.split("!").first, "/elasticsearch-template.json"].join("!")
          @template = jar_path
        rescue => ex
          raise "Failed to cache, due to: #{ex}\n#{ex.backtrace}"
        end
      else
        if File.exists?("elasticsearch-template.json")
          @template = "elasticsearch-template.json"
        elsif File.exists?("lib/logstash/outputs/elasticsearch-template.json")
          @template = "lib/logstash/outputs/elasticsearch-template.json"
        else
          raise "You must specify 'template => ...' in your elasticsearch_http output"
        end
      end
    end
    @template_json = IO.read(@template).gsub(/\n/,'')
    @logger.info("Using mapping template", :template => @template_json)
  end # def get_template
  
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
    buffer_receive([event, event.sprintf(@index), event.sprintf(@index_type)])
  end # def receive

  def flush(events, teardown=false)
    request = @client.bulk
    events.each do |event, index, type|
      type = "logs" if type.empty?
      if @document_id
        request.index(index, type, event.sprintf(@document_id), event.to_json)
      else
        request.index(index, type, nil, event.to_json)
      end
    end

    request.execute!
    # TODO(sissel): Handle errors. Since bulk requests could mostly succeed
    # (aka partially fail), we need to figure out what documents need to be
    # retried.
  end # def flush

end # class LogStash::Outputs::Elasticsearch
