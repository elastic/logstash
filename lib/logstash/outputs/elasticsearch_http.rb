# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"
require "stud/buffer"

# This output lets you store logs in Elasticsearch.
#
# This plugin uses the HTTP/REST interface to Elasticsearch, which usually
# lets you use any version of Elasticsearch server. It is known to work
# with elasticsearch %ELASTICSEARCH_VERSION%
#
# You can learn more about Elasticsearch at <http://www.elasticsearch.org>
class LogStash::Outputs::ElasticSearchHTTP < LogStash::Outputs::Base
  include Stud::Buffer

  DEFAULT_PORT = 9200

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
  # change this you will need to prune the old template manually, e.g.
  # curl -XDELETE <http://localhost:9200/_template/OldTemplateName?pretty>
  # where OldTemplateName is whatever the former setting was.
  config :template_name, :validate => :string, :default => "logstash"

  # You can set the path to your own template here, if you so desire.  
  # If not the included template will be used.
  config :template, :validate => :path

  # Overwrite the current template with whatever is configured 
  # in the template and template_name directives.
  config :template_overwrite, :validate => :boolean, :default => false

  # The list of address:port to reach a cluster of your Elasticsearch nodes. Default port is 9200
  # E.g. [localhost, localhost:9400] will be translated to [localhost:9200, localhost:9400]
  # Note: writes to Elasticsearch will happen in a round-robin fashion.
  config :host_list, :validate => :array, :required => true

  # The hostname or IP address to reach your Elasticsearch server.
  config :host, :validate => :string, :deprecated => "You can use host_list instead." 

  # The port for Elasticsearch HTTP interface to use.
  config :port, :validate => :number, :default => DEFAULT_PORT, :deprecated => "You can use host_list instead."

  # The HTTP Basic Auth username used to access your elasticsearch server.
  config :user, :validate => :string, :default => nil

  # The HTTP Basic Auth password used to access your elasticsearch server.
  config :password, :validate => :password, :default => nil

  # This plugin uses the bulk index api for improved indexing performance.
  # To make efficient bulk api calls, we will buffer a certain number of
  # events before flushing that out to Elasticsearch. This setting
  # controls how many events will be buffered before sending a batch
  # of events.
  config :flush_size, :validate => :number, :default => 100

  # The amount of time since last flush before a flush is forced.
  #
  # This setting helps ensure slow event rates don't get stuck in Logstash.
  # For example, if your `flush_size` is 100, and you have received 10 events,
  # and it has been more than `idle_flush_time` seconds since the last flush,
  # logstash will flush those 10 events automatically.
  #
  # This helps keep both fast and slow log streams moving along in
  # near-real-time.
  config :idle_flush_time, :validate => :number, :default => 1

  # The document ID for the index. Useful for overwriting existing entries in
  # Elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # Set the type of Elasticsearch replication to use. If async
  # the index request to Elasticsearch to return after the primary
  # shards have been written. If sync (default), index requests
  # will wait until the primary and the replica shards have been
  # written.
  config :replication, :validate => ['async', 'sync'], :default => 'sync'

  class NoLiveHost < StandardError; end

  public
  def register
    require "ftw" # gem ftw
    @agent = FTW::Agent.new
    @queue = []

    auth = @user && @password ? "#{@user}:#{@password.value}@" : ""
    @current_host_index = 0
    create_hosts(auth)
    @bulk_url = "http://%s/_bulk?replication=#{@replication}"
    @no_template = false
    if @manage_template
      begin
        manage_template
      rescue NoLiveHost => e
        @no_template = true
        @logger.error("All elasticsearch nodes are dead", :exception => e)
      end
    end # end if @manage_template
    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  protected
  def create_hosts(auth)
    @hosts = []
    @host_list.each do |host|
      if host.include? ':'
        host = "#{auth}#{host}"
      else
        host = "#{auth}#{host}:#{DEFAULT_PORT}"
      end
      @hosts << host
    end
    
    if @host != nil
      host = "#{auth}#{@host}:#{@port}"
      @hosts << host
    end
    @hosts = @hosts.uniq
  end # def create_hosts

  # issue http request in round-robin fashion
  protected
  def issue_request(command, url_format, body=nil)
    tries = @hosts.length - 1
    begin
      @current_host_index = (@current_host_index + 1) % @hosts.length
      host = @hosts[@current_host_index]
      url = url_format % host
      case command
      when 'get'
        return @agent.get!(url)
      when 'put'
        return @agent.put!(url, :body => body)
      when 'post'
        return @agent.post!(url, :body => body)
      when 'delete'
        return @agent.delete!(url)
      end
    rescue Errno::EBADF => e
      if tries <= 0
        raise NoLiveHost, "No hosts are alive"
      end
      tries -= 1
      retry
    end
  end # def issue_request

  protected
  def manage_template
    @logger.info("Automatic template management enabled", :manage_template => @manage_template.to_s)
    template_search_url = "http://%s/_template/*"
    @template_url = "http://%s/_template/#{@template_name}"
    if @template_overwrite
      @logger.info("Template overwrite enabled.  Deleting existing template.", :template_overwrite => @template_overwrite.to_s)
      response = issue_request('get', @template_url)
      template_action('delete') if response.status == 200 #=> Purge the old template if it exists
    end
    has_template = false
    template_idx_name = @index.sub(/%{[^}]+}/,'*')
    alt_template_idx_name = @index.sub(/-%{[^}]+}/,'*')
    # Get the template data
    response = issue_request('get', template_search_url)
    @logger.debug("Template Search URL:", :template_search_url => template_search_url % @hosts[@current_host_index])
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
  end
    
  public 
  def template_action(command)
    begin
      if command == 'delete'
        response = issue_request('delete', @template_url)
        response.discard_body
      elsif command == 'put'
        response = issue_request('put', @template_url, @template_json)
        response.discard_body
      end
    rescue EOFError
      @logger.warn("EOF while attempting request or reading response header from elasticsearch",
                   :host => @hosts[@current_host_index])
      return # abort this action
    end
    if response.status != 200
      @logger.error("Error acting on elasticsearch mapping template",
                    :response => response, :action => command,
                    :request_url => @template_url % @hosts[@current_host_index])
      return
    end
    @logger.info("Successfully deleted template", :template_url => @template_url % @hosts[@current_host_index]) if command == 'delete'
    @logger.info("Successfully applied template", :template_url => @template_url % @hosts[@current_host_index]) if command == 'put'
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
        elsif File.exists?("lib/logstash/outputs/elasticsearch/elasticsearch-template.json")
          @template = "lib/logstash/outputs/elasticsearch/elasticsearch-template.json"
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
    # check if template has been created
    if @no_template
      begin
        manage_template
      rescue NoLiveHost => e
        @logger.error("All elasticsearch nodes are dead", :exception => e)
        return # abort this flush
      end
      @no_template = false
    end

    begin
      response = issue_request('post', @bulk_url, body)
    rescue EOFError
      @logger.warn("EOF while writing request or reading response header from elasticsearch",
                  :host => @hosts[@current_host_index])
      return # abort this flush
    rescue NoLiveHost => e
      @logger.error("All elasticsearch nodes are dead", :exception => e)
      return # abort this flush
    end

    # Consume the body for error checking
    # This will also free up the connection for reuse.
    body = ""
    begin
      response.read_body { |chunk| body += chunk }
    rescue EOFError
      @logger.warn("EOF while reading response body from elasticsearch",
                   :host => @hosts[@current_host_index])
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
