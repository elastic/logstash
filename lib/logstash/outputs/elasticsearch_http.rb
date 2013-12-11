# encoding: utf-8
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

  # The hostname or ip address to reach your elasticsearch server.
  config :host, :validate => :string, :required => true

  # The port for ElasticSearch HTTP interface to use.
  config :port, :validate => :number, :default => 9200

  # The HTTP Basic Auth username used to access your elasticsearch server.
  config :user, :validate => :string, :default => nil

  # The HTTP Basic Auth password used to access your elasticsearch server.
  config :password, :validate => :password, :default => nil

  # This plugin uses the bulk index api for improved indexing performance.
  # To make efficient bulk api calls, we will buffer a certain number of
  # events before flushing that out to elasticsearch. This setting
  # controls how many events will be buffered before sending a batch
  # of events.
  config :flush_size, :validate => :number, :default => 100

  # The amount of time since last flush before a flush is forced.
  #
  # This setting helps ensure slow event rates don't get stuck in logstash.
  # For example, if your `flush_size` is 100, and you have received 10 events,
  # and it has been more than `idle_flush_time` seconds since the last flush,
  # logstash will flush those 10 events automatically.
  #
  # This helps keep both fast and slow log streams moving along in
  # near-real-time.
  config :idle_flush_time, :validate => :number, :default => 1

  # The document ID for the index. Useful for overwriting existing entries in
  # elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # Set the type of elasticsearch replication to use. If async
  # the index request to elasticsearch to return after the primary
  # shards have been written. If sync (default), index requests
  # will wait until the primary and the replica shards have been
  # written.
  config :replication, :validate => ['async', 'sync'], :default => 'sync'

  public
  def register
    require "ftw" # gem ftw
    @agent = FTW::Agent.new
    @queue = []

    auth = @user && @password ? "#{@user}:#{@password.value}@" : ""
    @bulk_url = "http://#{auth}#{@host}:#{@port}/_bulk?replication=#{@replication}"
    if @manage_template
      @logger.info("Automatic template configuration enabled", :manage_template => @manage_template.to_s)
      template_search_url = "http://#{auth}#{@host}:#{@port}/_template/*"
      @template_url = "http://#{auth}#{@host}:#{@port}/_template/#{@template_name}"
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
                   :host => @host, :port => @port)
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

  public
  def receive(event)
    return unless output?(event)
    buffer_receive([event, index, type])
  end # def receive

  def flush(events, teardown=false)
    # Avoid creating a new string for newline every time
    newline = "\n".freeze

    body = events.collect do |event, index, type|
      index = event.sprintf(@index)

      # Set the 'type' value for the index.
      if @index_type.nil?
        type =  event["type"] || "logs"
      else
        type = event.sprintf(@index_type)
      end
      header = { "index" => { "_index" => index, "_type" => type } }
      header["index"]["_id"] = event.sprintf(@document_id) if !@document_id.nil?

      [ header.to_json, newline, event.to_json, newline ]
    end.flatten
    post(body.join(""))
  end # def receive_bulk

  def post(body)
    begin
      response = @agent.post!(@bulk_url, :body => body)
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
