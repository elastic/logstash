# encoding: utf-8
require "logstash/environment"
require "logstash/namespace"
require "logstash/outputs/base"
require "json"
require "uri"
require "net/http"

# This output lets you store logs in elasticsearch. It's similar to the
# 'elasticsearch' output but improves performance by using a queue server,
# rabbitmq, to send data to elasticsearch.
#
# Upon startup, this output will automatically contact an elasticsearch cluster
# and configure it to read from the queue to which we write.
#
# You can learn more about elasticseasrch at <http://elasticsearch.org>
# More about the elasticsearch rabbitmq river plugin: <https://github.com/elasticsearch/elasticsearch-river-rabbitmq/blob/master/README.md>

class LogStash::Outputs::ElasticSearchRiver < LogStash::Outputs::Base

  config_name "elasticsearch_river"
  milestone 2

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indeces by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string, :default => "%{type}"

  # The name/address of an ElasticSearch host to use for river creation
  config :es_host, :validate => :string, :required => true

  # ElasticSearch API port
  config :es_port, :validate => :number, :default => 9200

  # ElasticSearch river configuration: bulk fetch size
  config :es_bulk_size, :validate => :number, :default => 1000

  # ElasticSearch river configuration: bulk timeout in milliseconds
  config :es_bulk_timeout_ms, :validate => :number, :default => 100

  # ElasticSearch river configuration: is ordered?
  config :es_ordered, :validate => :boolean, :default => false

  # Hostname of RabbitMQ server
  config :rabbitmq_host, :validate => :string, :required => true

  # Port of RabbitMQ server
  config :rabbitmq_port, :validate => :number, :default => 5672

  # RabbitMQ user
  config :user, :validate => :string, :default => "guest"

  # RabbitMQ password
  config :password, :validate => :string, :default => "guest"

  # RabbitMQ vhost
  config :vhost, :validate => :string, :default => "/"

  # RabbitMQ queue name
  config :queue, :validate => :string, :default => "elasticsearch"

  # RabbitMQ exchange name
  config :exchange, :validate => :string, :default => "elasticsearch"

  # The exchange type (fanout, topic, direct)
  config :exchange_type, :validate => [ "fanout", "direct", "topic"],
         :default => "direct"

  # RabbitMQ routing key
  config :key, :validate => :string, :default => "elasticsearch"

  # RabbitMQ durability setting. Also used for ElasticSearch setting
  config :durable, :validate => :boolean, :default => true

  # RabbitMQ persistence setting
  config :persistent, :validate => :boolean, :default => true

  # The document ID for the index. Useful for overwriting existing entries in
  # elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  public
  def register
    LogStash::Environment.load_elasticsearch_jars!
    prepare_river
  end

  protected
  def prepare_river
    require "logstash/outputs/rabbitmq"

    # Configure the message plugin
    params = {
      "host" => [@rabbitmq_host],
      "port" => [@rabbitmq_port],
      "user" => [@user],
      "password" => [@password],
      "exchange_type" => [@exchange_type],
      "exchange" => [@exchange],
      "key" => [@key],
      "vhost" => [@vhost],
      "durable" => [@durable.to_s],
      "persistent" => [@persistent.to_s],
      "debug" => [@logger.debug?.to_s],
    }.reject {|k,v| v.first.nil?}
    @mq = LogStash::Outputs::RabbitMQ.new(params)
    @mq.register

    # Set up the river
    begin
      auth = "#{@user}:#{@password}"

      # Name the river by our hostname
      require "socket"
      hostname = Socket.gethostname

      # Replace spaces with hyphens and remove all non-alpha non-dash non-underscore characters
      river_name = "#{hostname} #{@queue}".gsub(' ', '-').gsub(/[^\w-]/, '')

      api_path = "/_river/logstash-#{river_name}/_meta"
      @status_path = "/_river/logstash-#{river_name}/_status"

      river_config = {"type" => "rabbitmq",
                      "rabbitmq" => {
                                "host" => @rabbitmq_host=="localhost" ? hostname : @rabbitmq_host,
                                "port" => @rabbitmq_port,
                                "user" => @user,
                                "pass" => @password,
                                "vhost" => @vhost,
                                "queue" => @queue,
                                "exchange" => @exchange,
                                "routing_key" => @key,
                                "exchange_type" => @exchange_type,
                                "exchange_durable" => @durable.to_s,
                                "queue_durable" => @durable.to_s
                               },
                      "index" => {"bulk_size" => @es_bulk_size,
                                 "bulk_timeout" => "#{@es_bulk_timeout_ms}ms",
                                 "ordered" => @es_ordered
                                },
                     }
      @logger.info("ElasticSearch using river", :config => river_config)
      Net::HTTP.start(@es_host, @es_port) do |http|
        req = Net::HTTP::Put.new(api_path)
        req.body = river_config.to_json
        response = http.request(req)
        response.value() # raise an exception if error
        @logger.info("River created: #{response.body}")
      end
    rescue Exception => e
      # TODO(petef): should we just throw an exception here, so the
      # agent tries to restart us and we in turn retry the river
      # registration?
      @logger.warn("Couldn't set up river. You'll have to set it up manually (or restart)", :exception => e)
    end

    check_river_status
  end # def prepare_river

  private
  def check_river_status
    tries = 0
    success = false
    reason = nil
    begin
      while !success && tries <= 3 do
        tries += 1
        Net::HTTP.start(@es_host, @es_port) do |http|
          req = Net::HTTP::Get.new(@status_path)
          response = http.request(req)
          response.value
          status = JSON.parse(response.body)
          @logger.debug("Checking ES river status", :status => status)
          if status["_source"]["error"]
            reason = "ES river status: #{status["_source"]["error"]}"
          else
            success = true
          end
        end
        sleep(2)
      end
    rescue Exception => e
      raise "river is not running, checking status failed: #{$!}"
    end

    raise "river is not running: #{reason}" unless success
  end # def check_river_status

  public
  def receive(event)
    return unless output?(event)
    # River events have a format of
    # "action\ndata\n"
    # where 'action' is index or delete, data is the data to index.
    header = { "index" => { "_index" => event.sprintf(@index), "_type" => event.sprintf(@index_type) } }
    if !@document_id.nil?
      header["index"]["_id"] = event.sprintf(@document_id)
    end

    @mq.publish_serialized(header.to_json + "\n" + event.to_json + "\n")
  end # def receive
end # LogStash::Outputs::ElasticSearchRiver
