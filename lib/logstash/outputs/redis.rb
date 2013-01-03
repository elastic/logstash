require "logstash/outputs/base"
require "logstash/namespace"

# send events to a redis database using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

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

  public
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

    @pending = Hash.new { |h, k| h[k] = [] }
    @last_pending_flush = Time.now.to_f
    if @batch and @data_type != "list"
      raise RuntimeError.new(
        "batch is not supported with data_type #{@data_type}"
      )
    end

    if @batch
      @flush_thread = Thread.new do
        while sleep(@batch_timeout) do
          process_pending(true)
        end
      end
    end

    @redis = nil
    if @shuffle_hosts
        @host.shuffle!
    end
    @host_idx = 0
    @pending_mutex = Mutex.new
  end # def register

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
  private
  def identity
    @name || "redis://#{@password}@#{@current_host}:#{@current_port}/#{@db} #{@data_type}:#{@key}"
  end

  public
  def receive(event)
    return unless output?(event)

    if @batch
      @pending[event.sprintf(@key)] << event.to_json
      process_pending
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

  private
  def process_pending(force=false)
    if !@pending_mutex.try_lock # failed to get lock
      return
    end

    pending_count = 0
    @pending.each { |k, v| pending_count += v.length }
    time_since_last_flush = Time.now.to_f - @last_pending_flush

    if (force && pending_count > 0) ||
       (pending_count >= @batch_events) ||
       (time_since_last_flush >= @batch_timeout && pending_count > 0)
      @logger.debug("Flushing redis output",
                    :pending_count => pending_count,
                    :time_since_last_flush => time_since_last_flush,
                    :batch_events => @batch_events,
                    :batch_timeout => @batch_timeout,
                    :force => force)
      begin
        @redis ||= connect
        @pending.each do |k, v|
          @redis.rpush(k, v)
          @pending.delete(k)
        end
        @last_pending_flush = Time.now.to_f
      rescue => e
        @logger.warn("Failed to send backlog of events to redis",
                     :pending_count => pending_count,
                     :identity => identity, :exception => e,
                     :backtrace => e.backtrace)
        sleep 1
        retry
      end
    end

    @pending_mutex.unlock
  end

  public
  def teardown
    process_pending(true)
    if @data_type == 'channel' and @redis
      @redis.quit
      @redis = nil
    end
  end

end
