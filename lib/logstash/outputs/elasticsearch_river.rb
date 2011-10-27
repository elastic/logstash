require "logstash/namespace"
require "logstash/outputs/base"
require "json"
require "uri"
require "net/http"

# This output lets you store logs in elasticsearch. It's similar to the
# 'elasticsearch' output but improves performance by using an AMQP server,
# such as rabbitmq, to send data to elasticsearch.
#
# Upon startup, this output will automatically contact an elasticsearch cluster
# and configure it to read from the queue to which we write.
#
# You can learn more about elasticseasrch at <http://elasticsearch.org>

class LogStash::Outputs::ElasticSearchRiver < LogStash::Outputs::Base

  config_name "elasticsearch_river"

  config :debug, :validate => :boolean, :default => false

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indeces by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The type to write events to. Generally you should try to write only similar
  # events to the same 'type'. String expansion '%{foo}' works here.
  config :type, :validate => :string, :default => "%{@type}"

  # The name/address of an ElasticSearch host to use for river creation
  config :es_host, :validate => :string, :required => true

  # ElasticSearch API port
  config :es_port, :validate => :number, :default => 9200

  # ElasticSearch river configuration: bulk fetch size
  config :es_bulk_size, :validate => :number, :default => 1000

  # ElasticSearch river configuration: bulk timeout in milliseconds
  config :es_bulk_timeout_ms, :validate => :number, :default => 100

  # Hostname of AMQP server
  config :amqp_host, :validate => :string, :required => true

  # Port of AMQP server
  config :amqp_port, :validate => :number, :default => 5672

  # AMQP user
  config :user, :validate => :string, :default => "guest"

  # AMQP password
  config :password, :validate => :string, :default => "guest"

  # AMQP vhost
  config :vhost, :validate => :string, :default => "/"

  # AMQWP queue name
  config :queue, :validate => :string, :default => "elasticsearch"

  # AMQP exchange name
  config :exchange, :validate => :string, :default => "elasticsearch"

  # AMQP routing key
  config :key, :validate => :string, :default => "elasticsearch"

  # AMQP durability setting. Also used for ElasticSearch setting
  config :durable, :validate => :boolean, :default => true

  # AMQP persistence setting
  config :persistent, :validate => :boolean, :default => true

  public
  def register
    # TODO(sissel): find a better way of declaring where the elasticsearch
    # libraries are
    # TODO(sissel): can skip this step if we're running from a jar.
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/**/*.jar")
    Dir[jarpath].each do |jar|
        require jar
    end
    prepare_river
  end

  protected
  def prepare_river
    require "logstash/outputs/amqp"

    # Configure the message plugin
    params = {
      "host" => [@amqp_host],
      "port" => [@amqp_port],
      "user" => [@user],
      "password" => [@password],
      "exchange_type" => ["direct"],
      "queue_name" => [@queue],
      "name" => [@exchange],
      "key" => [@key],
      "vhost" => [@vhost],
      "durable" => [@durable.to_s],
      "persistent" => [@persistent.to_s],
      "debug" => [@debug.to_s],
    }.reject {|k,v| v.nil?}
    @mq = LogStash::Outputs::Amqp.new(params)
    @mq.register

    # Set up the river
    begin
      auth = "#{@user}:#{@password}"

      # Name the river by our hostname
      require "socket"
      hostname = Socket.gethostname
      api_path = "/_river/logstash-#{hostname.gsub('.','_')}/_meta"

      river_config = {"type" => "rabbitmq",
                      "rabbitmq" => {
                                "host" => @amqp_host=="localhost" ? hostname : @amqp_host,
                                "port" => @amqp_port,
                                "user" => @user,
                                "pass" => @password,
                                "vhost" => @vhost,
                                "queue" => @queue,
                                "exchange" => @exchange,
                                "routing_key" => @key,
                                "exchange_durable" => @durable,
                                "queue_durable" => @durable,
                               },
                      "index" => {"bulk_size" => @es_bulk_size,
                                 "bulk_timeout" => "#{@es_bulk_timeout_ms}ms",
                                },
                     }
      @logger.info(["ElasticSearch using river", river_config])
      Net::HTTP.start(@es_host, @es_port) do |http|
        req = Net::HTTP::Put.new(api_path)
        req.body = river_config.to_json
        response = http.request(req)
        response.value() # raise an exception if error
        @logger.info("River created: #{response.body}")
      end
    rescue Exception => e
      @logger.warn "Couldn't set up river: #{e.inspect}. You'll have to set it up manually (or restart)"
    end
  end

  public
  def receive(event)
    return unless output?(event)

    index_message = {"index" => {"_index" => event.sprintf(@index), "_type" => event.sprintf(@type)}}.to_json + "\n"
    index_message += event.to_hash.to_json + "\n"
    @mq.receive_raw(index_message)
  end
end

