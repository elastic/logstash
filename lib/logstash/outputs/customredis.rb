require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"

class LogStash::Outputs::CustomRedis < LogStash::Outputs::Base

  include Stud::Buffer

  config_name "customredis"
  milestone 2

  config :name, :validate => :string, :default => 'default', :deprecated => true
  config :host, :validate => :array, :default => ["127.0.0.1"]
  config :shuffle_hosts, :validate => :boolean, :default => true
  config :port, :validate => :number, :default => 6379
  config :db, :validate => :number, :default => 0
  config :timeout, :validate => :number, :default => 5
  config :password, :validate => :password
  config :queue, :validate => :string, :deprecated => true
  config :key, :validate => :string, :required => true
  config :batch_events, :validate => :number, :default => 50
  config :batch_timeout, :validate => :number, :default => 5
  config :reconnect_interval, :validate => :number, :default => 1
  config :congestion_threshold, :validate => :number, :default => 0
  config :congestion_interval, :validate => :number, :default => 1

  config :luascript, :validate => :string, :required => true
  
  default :codec, "json"
  
  def register
    require 'redis'

    @data_type = "list"
    buffer_initialize(
	:max_items => @batch_events,
	:max_interval => @batch_timeout,
	:logger => @logger
    )

    @redis = nil
    if @shuffle_hosts
        @host.shuffle!
    end
    @host_idx = 0

    @congestion_check_times = Hash.new { |h,k| h[k] = Time.now.to_i - @congestion_interval }
	
    @codec.on_event do |payload|
	buffer_receive(payload, @key)
    end
  end # def register

  def receive(event)
    return unless output?(event)
	@codec.encode(event)
	
  end # def receive

  def congestion_check(key)
    return if @congestion_threshold == 0
    if (Time.now.to_i - @congestion_check_times[key]) >= @congestion_interval # Check congestion only if enough time has passed since last check.
      while @redis.llen(key) > @congestion_threshold # Don't push event to redis key which has reached @congestion_threshold.
        @logger.warn? and @logger.warn("Redis key size has hit a congestion threshold #{@congestion_threshold} suspending output for #{@congestion_interval} seconds")
        sleep @congestion_interval
      end
      @congestion_check_time = Time.now.to_i
    end
  end

  # called from Stud::Buffer#buffer_flush when there are events to flush
  def flush(events, key, teardown=false)
    @redis ||= connect
    # we should not block due to congestion on teardown
    # to support this Stud::Buffer#buffer_flush should pass here the :final boolean value.
    congestion_check(key) unless teardown
    @redis.evalsha(@sha, :keys => [ @key ], :argv => events)
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
	buffer_flush(:final => true)
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

    r = Redis.new(params)

    # Deploy LUA script
    @sha = r.script(:load, @luascript)
    @logger.debug(@sha + ' deployed')

    r
  end # def connect

  @sha

  # A string used to identify a redis instance in log messages
  def identity
    @name || "redis://#{@password}@#{@current_host}:#{@current_port}/#{@db} #{@data_type}:#{@key}"
  end

end
