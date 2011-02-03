require "em-http-request"
require "logstash/namespace"
require "logstash/outputs/amqp"
require "logstash/outputs/base"

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

    indexurl = @esurl.to_s
    indexmap_http = EventMachine::HttpRequest.new(indexurl)
    indexmap_req = indexmap_http.put :body => indexmap.to_json
    indexmap_req.callback do
      @logger.info(["Done configuring index", indexurl, indexmap])
      ready(params)
    end
    indexmap_req.errback do
      @logger.warn(["Failure configuring index", @esurl.to_s, indexmap])
    end
  end # def register

  public
  def ready(params)
    case params["method"]
    when "http"
      @logger.debug "ElasticSearch using http with URL #{@url.to_s}"
      @http = EventMachine::HttpRequest.new(@url.to_s)
      @callback = self.method(:receive_http)
    when "river"
      params["port"] ||= 5672
      mq_url = URI::parse("amqp://#{params["host"]}:#{params["port"]}/queue/#{params["queue"]}?durable=1")
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
      http_setup = EventMachine::HttpRequest.new(em_url.to_s)
      req = http_setup.put :body => river_config.to_json
      req.errback do
        @logger.warn "Error setting up river: #{req.response}"
      end
      @callback = self.method(:receive_river)
    else raise "unknown elasticsearch method #{params["method"].inspect}"
    end

    receive(LogStash::Event.new({
      "@source" => "@logstashinit",
      "@type" => "@none",
      "@message" => "Starting logstash output to elasticsearch",
      "@fields" => {
        "HOSTNAME" => Socket.gethostname
      },
    }))

    pending = @pending
    @pending = []
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
      $stderr.puts "Request to index to #{@url.to_s} failed (will retry, #{tries} tries left). Event was #{event.to_s}"
      EventMachine::add_timer(2) do
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
