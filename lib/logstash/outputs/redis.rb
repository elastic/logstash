require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"

# send events to a redis database using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

  include Stud::Buffer

  config_name "redis"
  plugin_status "beta"

  # Name is used for logging in case there are multiple instances.
  # TODO: delete
  config :name, :validate => :string, :default => 'default',
    :deprecated => true

  # The hostname(s) of your redis server(s). Ports may be specified on any
  # hostname, which will override the global port config.
  #
  # For example:
  #
  #     "127.0.0.1"
  #     ["127.0.0.1", "127.0.0.2"]
  #     ["127.0.0.1:6380", "127.0.0.1"]
  config :host, :validate => :array, :default => ["127.0.0.1"]

  # Shuffle the host list during logstash startup.
  config :shuffle_hosts, :validate => :boolean, :default => true

  # The default port to connect on. Can be overridden on any hostname.
  config :port, :validate => :number, :default => 6379

  # The redis database number.
  config :db, :validate => :number, :default => 0

  # Redis initial connection timeout in seconds.
  config :timeout, :validate => :number, :default => 5

  # Password to authenticate with.  There is no authentication by default.
  config :password, :validate => :password

  # The name of the redis queue (we'll use RPUSH on this). Dynamic names are
  # valid here, for example "logstash-%{@type}"
  # TODO: delete
  config :queue, :validate => :string, :deprecated => true

  # The name of a redis list or channel. Dynamic names are
  # valid here, for example "logstash-%{@type}".
  # TODO set required true
  config :key, :validate => :string, :required => false

  # Either list or channel.  If redis_type is list, then we will RPUSH to key.
  # If redis_type is channel, then we will PUBLISH to key.
  # TODO set required true
  config :data_type, :validate => [ "list", "channel" ], :required => false

  # Set to true if you want redis to batch up values and send 1 RPUSH command
  # instead of one command per value to push on the list.  Note that this only
  # works with data_type="list" mode right now.
  #
  # If true, we send an RPUSH every "batch_events" events or
  # "batch_timeout" seconds (whichever comes first).
  config :batch, :validate => :boolean, :default => false

  # If batch is set to true, the number of events we queue up for an RPUSH.
  config :batch_events, :validate => :number, :default => 50

  # If batch is set to true, the maximum amount of time between RPUSH commands
  # when there are pending events to flush.
  config :batch_timeout, :validate => :number, :default => 5

  def register
    require 'redis'

    # TODO remove after setting key and data_type to true
    if @queue
      if @key or @data_type
        raise RuntimeError.new(
          "Cannot specify queue parameter and key or data_type"
        )
      end
      @key = @queue
      @data_type = 'list'
    end

    if not @key or not @data_type
      raise RuntimeError.new(
        "Must define queue, or key and data_type parameters"
      )
    end
    # end TODO


    if @batch
      if @data_type != "list"
        raise RuntimeError.new(
          "batch is not supported with data_type #{@data_type}"
        )
      end
      buffer_initialize(
        :max_items => @batch_events,
        :max_interval => @batch_timeout,
        :logger => @logger
      )
    end

    @redis = nil
    if @shuffle_hosts
        @host.shuffle!
    end
    @host_idx = 0
  end # def register

  def receive(event)
    return unless output?(event)

    if @batch
      # Stud::Buffer
      buffer_receive(event.to_json, event.sprintf(@key))
      return
    end

    event_key_and_payload = [event.sprintf(@key), event.to_json]

    begin
      @redis ||= connect
      if @data_type == 'list'
        @redis.rpush *event_key_and_payload
      else
        @redis.publish *event_key_and_payload
      end
    rescue => e
      @logger.warn("Failed to send event to redis", :event => event,
                   :identity => identity, :exception => e,
                   :backtrace => e.backtrace)
      sleep 1
      @redis = nil
      retry
    end
  end # def receive

  # called from Stud::Buffer#buffer_flush when there are events to flush
  def flush(events, key)
    @redis ||= connect
    @redis.rpush(key, events)
  end
  # called from Stud::Buffer#buffer_flush when an error occurs
  def on_flush_error(e)
    @logger.warn("Failed to send backlog of events to redis",
      :identity => identity,
      :exception => e,
      :backtrace => e.backtrace
    )
    @redis = connect
  end

  def teardown
    if @batch
      buffer_flush(:final => true)
    end
    if @data_type == 'channel' and @redis
      @redis.quit
      @redis = nil
    end
  end

  private
  def connect
    @current_host, @current_port = @host[@host_idx].split(':')
    @host_idx = @host_idx + 1 >= @host.length ? 0 : @host_idx + 1

    if not @current_port
      @current_port = @port
    end

    params = {
      :host => @current_host,
      :port => @current_port,
      :timeout => @timeout,
      :db => @db
    }
    @logger.debug(params)

    if @password
      params[:password] = @password.value
    end

    Redis.new(params)
  end # def connect

  # A string used to identify a redis instance in log messages
  def identity
    @name || "redis://#{@password}@#{@current_host}:#{@current_port}/#{@db} #{@data_type}:#{@key}"
  end

end
