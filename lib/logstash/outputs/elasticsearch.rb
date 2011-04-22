require "em-http-request"
require "logstash/namespace"
require "logstash/outputs/amqp"
require "logstash/outputs/base"
require "cgi"

class LogStash::Outputs::Elasticsearch < LogStash::Outputs::Base
  public
  def register
    @pending = []
    # Port?
    # Authentication?
    @esurl = @url.clone
    @esurl.scheme = "http"
    @esurl.path = "/" + @url.path.split("/")[1]
    defaults = {"method" => "http"}
    params = defaults.merge(@urlopts)

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

    #puts :waiting
    puts @esurl.to_s
    #sleep 10
    indexurl = @esurl.to_s
    indexmap_http = EventMachine::HttpRequest.new(indexurl)
    indexmap_req = indexmap_http.put :body => indexmap.to_json
    indexmap_req.callback do
      @logger.info(["Done configuring index", indexurl, indexmap])
      ready(params)
    end
    indexmap_req.errback do
      @logger.warn(["Failure configuring index (http failed to connect?)",
                    @esurl.to_s, indexmap])
      @logger.warn([indexmap_req])
      #sleep 30
      raise "Failure configuring index: #{@esurl.to_s}"
      
    end
  end # def register

  public
  def ready(params)
    method = params.delete("method")
    case method
    when "http"
      @logger.debug "ElasticSearch using http with URL #{@url.to_s}"
      @http = EventMachine::HttpRequest.new(@url.to_s)
      @callback = self.method(:receive_http)
    when "river"
      river_type = params.delete("type") || "rabbitmq"
      amqp_host = params.delete("host") || 'localhost'
      amqp_port = params.delete("port") || 5672
      amqp_exchange_type = params.delete("exchange_type") || "direct"
      amqp_queue_name = params.delete("queue") || "es"
      amqp_exchange_name = params.delete("exchange") || amqp_queue_name
      amqp_exchange_durable = (params["durable"] || "false") =~ /^[ty1]/
      amqp_user = params.delete("user") or "guest"
      amqp_pass = params.delete("pass") or "guest"
      amqp_vhost = params.delete("vhost") || "/"
      vhost_str = (amqp_vhost == "/") ? "" : "/#{amqp_vhost}"
      qs = params.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
      mq_url = URI::parse("amqp://#{amqp_user}:#{amqp_pass}@#{amqp_host}:#{amqp_port}#{vhost_str}/#{amqp_exchange_type}/#{amqp_exchange_name}?#{qs}")
      @mq = LogStash::Outputs::Amqp.new(mq_url.to_s)
      @mq.register
      @callback = self.method(:receive_river)
      em_url = URI.parse("http://#{@url.host}:#{@url.port}/_river/logstash#{@url.path.tr("/", "_")}/_meta")
      unused, @es_index, @es_type = @url.path.split("/", 3)

      river_config = {
        "type" => river_type,
        river_type => {
          "host" => amqp_host,
          "user" => amqp_user,
          "port" => amqp_port,
          "pass" => amqp_pass,
          "vhost" => amqp_vhost,
          "queue" => amqp_queue_name,
          "exchange" => amqp_exchange_name,
          "exchange_durable" => amqp_exchange_durable ? "true" : "false",
          "exchange_type" => amqp_exchange_type,
          "routing_key" => "",
        },
        "index" => {
          "bulk_size" => 100,
          "bulk_timeout" => "10ms",
        },
      }
      @logger.debug(["ElasticSearch using river", river_config])
      http_setup = EventMachine::HttpRequest.new(em_url.to_s)
      req = http_setup.put :body => river_config.to_json
      req.errback do
        @logger.warn "Error setting up river: #{req.response}"
      end
      @callback = self.method(:receive_river)
    else raise "unknown elasticsearch method #{method.inspect}"
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
  def receive_river(event)
    # bulk format; see http://www.elasticsearch.com/docs/elasticsearch/river/rabbitmq/
    index_message = {"index" => {"_index" => @es_index, "_type" => @es_type}}.to_json + "\n"
    #index_message += {@es_type => event.to_hash}.to_json + "\n"
    index_message += event.to_hash.to_json + "\n"
    @mq.receive_raw(index_message)
  end # def receive_river
end # class LogStash::Outputs::Elasticsearch
