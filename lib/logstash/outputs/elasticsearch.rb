require "logstash/outputs/base"
require "logstash/outputs/amqp"
require "em-http-request"

class LogStash::Outputs::Elasticsearch < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    # Port?
    # Authentication?
    @httpurl = @url.clone
    @httpurl.scheme = "http"
    defaults = {"method" => "http"}
    params = defaults.merge(@urlopts)

    # Describe this index to elasticsearch
    indexmap = {
      # The name of the index
      "settings": { 
        @httpurl.path.split("/")[-1] => {
          "properties" => {
            "@source" => { "type" => "string" },
            "@source_host" => { "type" => "string" },
            "@source_path" => { "type" => "string" },
            "@timestamp" => { "type" => "date" },
            "@tags" => { "type" => "string" },
            "@message" => { "type" => "string" },

            # TODO(sissel): Hack for now until this bug is resolved:
            # https://github.com/elasticsearch/elasticsearch/issues/issue/604
            "@fields" => { 
              "type": "object"
              "properties" => {
                "HOSTNAME" => { "type" => "string" },
              },
            }, # "@fields"
          }, # "properties"
        }, # index map for this index type.
      }, # "settings"
    } # ES Index

    indexurl = @httpurl.to_s + "/_mapping"
    indexmap_http = EventMachine::HttpRequest.new(indexurl)
    indexmap_req = indexmap_http.put :body => indexmap.to_json
    indexmap_req.callback do
      @logger.info(["Done configuring index", indexurl, indexmap])
      ready(params)
    end
    indexmap_req.errback do
      @logger.warn(["Failure configuring index", @httpurl.to_s, indexmap])
    end
  end # def register

  def ready(params)
    case params["method"]
    when "http"
      @logger.debug "ElasticSearch using http with URL #{@httpurl.to_s}"
      @http = EventMachine::HttpRequest.new(@httpurl.to_s)
      @callback = self.method(:receive_http)
    when "river"
      params["port"] ||= 5672
      mq_url = URI::parse("amqp://#{params["host"]}:#{params["port"]}/queue/#{params["queue"]}?durable=1")
      @mq = LogStash::Outputs::Amqp.new(mq_url.to_s)
      @mq.register
      @callback = self.method(:receive_river)
      em_url = URI.parse("http://#{@httpurl.host}:#{@httpurl.port}/_river/logstash#{@httpurl.path.tr("/", "_")}/_meta")
      unused, @es_index, @es_type = @httpurl.path.split("/", 3)

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
    else raise "unknown elasticsearch method #{params["method"].inspect}"
    end
  end # def ready

  def receive(event)
    @callback.call(event)
  end # def receive

  def receive_http(event, tries=5)
    req = @http.post :body => event.to_json
    req.errback do
      $stderr.puts "Request to index to #{@httpurl.to_s} failed (will retry, #{tries} tries left). Event was #{event.to_s}"
      EventMachine::add_timer(2) do
        receive_http(event, tries - 1)
      end
    end
  end # def receive_http

  def receive_river(event)
    # bulk format; see http://www.elasticsearch.com/docs/elasticsearch/river/rabbitmq/
    index_message = {"index" => {"_index" => @es_index, "_type" => @es_type}}.to_json + "\n"
    #index_message += {@es_type => event.to_hash}.to_json + "\n"
    index_message += event.to_hash.to_json + "\n"
    @mq.receive_raw(index_message)
  end # def receive_river
end # class LogStash::Outputs::Websocket
