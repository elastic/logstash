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

    case params["method"]
    when "http"
      @logger.debug "ElasticSearch using http with URL #{@httpurl.to_s}"
      @http = EventMachine::HttpRequest.new(@httpurl.to_s)
      @callback = self.method(:receive_http)
    when "river"
      mq_url = URI::parse("amqp://#{params["host"]}/queue/#{params["queue"]}?durable=1")
      @mq = LogStash::Outputs::Amqp.new(mq_url.to_s)
      @mq.register
      @callback = self.method(:receive_river)
      em_url = URI.parse("http://#{@httpurl.host}:#{@httpurl.port}/_river/logstash#{@httpurl.path.tr("/", "_")}/_meta")
      unused, @es_index, @es_type = @httpurl.path.split("/", 3)

      river_config = {"type" => params["type"],
                      params["type"] => {"host" => params["host"],
                                         "user" => params["user"],
                                         "pass" => params["pass"],
                                         "vhost" => params["vhost"],
                                         "queue" => params["queue"],
                                         "exchange" => params["queue"],
                                        },
                     "index" => {"bulk_size" => 100,
                                 "bulk_timeout" => "10ms",
                                },
                     }
      @logger.debug "ElasticSearch using river with config #{river_config.awesome_inspect}"
      http_setup = EventMachine::HttpRequest.new(em_url.to_s)
      req = http_setup.put :body => river_config.to_json
      req.errback do
        @logger.warn "Error setting up river: #{req.response}"
      end
    else raise "unknown elasticsearch method #{params["method"].inspect}"
    end
  end # def register

  def receive(event)
    @callback.call(event)
  end # def receive

  def receive_http(event)
    req = @http.post :body => event.to_json
    req.errback do
      $stderr.puts "Request to index to #{@httpurl.to_s} failed. Event was #{event.to_s}"
    end
  end # def receive_http

  def receive_river(event)
    # bulk format; see http://www.elasticsearch.com/docs/elasticsearch/river/rabbitmq/
    index_message = {"index" => {"_index" => @es_index, "_type" => @es_type}}.to_json + "\n"
    index_message += {@es_type => event.to_hash}.to_json + "\n"
    @mq.receive_raw(index_message)
  end # def receive_river
end # class LogStash::Outputs::Websocket
