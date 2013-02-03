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
  # Deprecated, does nothing.
  config :shuffle_hosts, :validate => :boolean, :default => true

  # Load balance between the redis hosts
  config :balance_hosts, :validate => :boolean, :default => true

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

  # Interval for reconnecting to failed redis connections
  config :reconnect_interval, :validate => :number, :default => 1

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

  # In case redis has more than @max_redis_events in the key, wait until someone consumes them, otherwise
  # if there are no consumers redis will run out of memory. Default value of 0 means that this limit is disabled.
  config :max_redis_events, :validate => :number, :default => 0

  # The limit of max events that can be buffered without blocking.
  # This does not include events which were dispatched to @batch_thread
  config :max_buffered_events, :validate => :number, :default => 10000

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

    @pending_count = 0
    @pending = Hash.new { |h, k| h[k] = [] }
    @last_pending_flush = Time.now.to_f
    if @batch and @data_type != "list"
      raise RuntimeError.new(
        "batch is not supported with data_type #{@data_type}"
      )
    end

    @main_thread = Thread.current
    
    # List of blocked threads
    @blocked_threads = []
    # Mutex to syncronize threads access to @blocked_threads
    @blocked_mutex = Mutex.new

    # Mutex to syncronize main plugin and @batch_thread threads on access to @pending beatch events buffer.
    @events_mutex = Mutex.new
    
    # List of active load balanced redis servers.
    @active_servers = []
    # Mutex to syncronize threads access to @active_servers.
    @lb_mutex = Mutex.new

    # Mutex to syncronize main plug

    @redis_pool = {}
    @host.each {|uri| @redis_pool[uri] = nil}

    connect

    # Dedicated reconnect thread
    @reconnect_thread = Thread.new do
      while sleep(@reconnect_interval) do
        connect unless @redis_pool.length == @active_servers.length
      end
    end

    if @batch
      @batch_thread = Thread.new do
        while true do
          Thread.stop
          process_pending
        end
      end
      @batch_sched_thread = Thread.new do
        while sleep(@batch_timeout) do
           @batch_thread.run if @batch_thread.status == "sleep"
        end
      end
    end
  end # def register

  private
  def connect
    @redis_pool.each_key do |uri|
      active = false
      @lb_mutex.synchronize { active = @active_servers.index(uri) }
      unless active
        begin
          @logger.debug("Connecting to redis", :uri => uri)
          host, port = uri.split(':')
          port = @port unless port
          @redis_pool[uri] = Redis.new(:host => host, :port => port,
                                       :timeout => @timeout, :db => @db,
                                       :password => @password.nil? ? nil : @password.value)
          @lb_mutex.synchronize { @active_servers << uri }
          @blocked_mutex.synchronize { @blocked_threads.shift.run while !@blocked_threads.empty? }
        rescue => e
          @logger.info("Failed connecting to redis", :host => uri, :exception => e, :backtrace => e.backtrace)
        end
      end
    end
  end # def connect

  public
  def receive(event)
    return unless output?(event)

    if @batch
      @events_mutex.synchronize do
        @pending[event.sprintf(@key)] << event.to_json
        @pending_count += 1
      end
      if @pending_count >= @max_buffered_events
        @logger.debug("Max redis output buffered events", :max_buffered_events => @max_buffered_events, :pending_count => @pending_count)
        @batch_thread.run if @batch_thread.status == "sleep"
        Thread.stop #Block until @batch_thread wakeup us once events have been pushed to redis.
      else
        if @pending_count >= @batch_events and !@active_servers.empty?
          @logger.debug("Batch thread invoke", :batch_events => @batch_events, :pending_count => @pending_count)
          @batch_thread.run if @batch_thread.status == "sleep"
        end
      end
      return
    end
 
    event_key_and_payload = [event.sprintf(@key), event.to_json]

    begin
      while @active_servers.empty? 
        @logger.debug("Could not connect to any of the redis servers")
        @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
        Thread.stop
      end
      if @data_type == 'list'
        while @redis_pool[@active_servers[0]].llen(@key) > @max_redis_events # Don't push event to redis key which has reached @max_redis_events
          @logger.info("Redis server has max allowed unconsumed events", :max_redis_events => @max_redis_events,
                       :events_in_redis => @redis_pool[@active_servers[0]].llen(@key), :host => @active_servers[0])
          @lb_mutex.synchronize { @active_servers.shift }
          while @active_servers.empty? # If all redis servers are full or inactive then sleep and try again
            @logger.warn("All redis servers are full or inactive")
            @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
            Thread.stop
          end
        end
        @redis_pool[@active_servers[0]].rpush *event_key_and_payload
      else
        @redis_pool[@active_servers[0]].publish *event_key_and_payload
      end
      @lb_mutex.synchronize { @active_servers << @active_servers.shift if @balance_hosts and @active_servers.length > 1 }
    rescue => e
      @logger.error("Failed to send event to redis", :event => event,
                   :host => @active_servers[0], :exception => e, :backtrace => e.backtrace)
      @lb_mutex.synchronize { @active_servers.shift }
      if @active_servers.empty? # If all redis servers are full or inactive then sleep and try again
        @logger.warn("Sending to all redis servers failed")
        @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
        Thread.stop
      end
      retry
    end
  end # def receive

  private
  def process_pending
    time_since_last_flush = Time.now.to_f - @last_pending_flush

    pending_events = nil
    pending_count = 0
    @events_mutex.synchronize do
      if @pending_count > 0
        pending_events, @pending = @pending, Hash.new { |h, k| h[k] = [] }
        pending_count ,@pending_count = @pending_count, 0
      end
    end

    if pending_events
      @logger.debug("Flushing redis output",
                    :pending_count => pending_count,
                    :time_since_last_flush => time_since_last_flush,
                    :batch_events => @batch_events,
                    :batch_timeout => @batch_timeout)
      begin
        while @active_servers.empty?
          @logger.warn("Could not connect to any of the redis servers")
          @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
          Thread.stop
        end
        while pending_events.length > 0
          pending_events.each do |k, v|
            if @redis_pool[@active_servers[0]].llen(k) < @max_redis_events # Don't push event to redis key which has reached @max_redis_events
              @redis_pool[@active_servers[0]].rpush(k, v)
              pending_events.delete(k)
            else
              @logger.info("Redis server has max allowed unconsumed events", :max_redis_events => @max_redis_events,
                          :events_in_redis => @redis_pool[@active_servers[0]].llen(k), :host => @active_servers[0])
            end
          end
          if pending_events.length > 0
            @lb_mutex.synchronize { @active_servers.shift }
            while @active_servers.empty? # If all redis servers are full or inactive then sleep and try again
              @logger.warn("All redis servers are full or inactive")
              @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
              Thread.stop
            end
          end
        end
        @last_pending_flush = Time.now.to_f
        @main_thread.run if @main_thread.status == "sleep" # Wakeup main thread in case it blocked itself due to @max_buffered_events
        @lb_mutex.synchronize { @active_servers << @active_servers.shift if @balance_hosts and @active_servers.length > 1 }
      rescue => e
        @logger.error("Failed to send backlog of events to redis", :pending_count => @pending_count,
                     :host => @active_servers[0], :exception => e, :backtrace => e.backtrace)
        @lb_mutex.synchronize { @active_servers.shift }
        if @active_servers.empty? # If all redis servers are full or inactive then sleep and try again
          @logger.warn("Sending to all redis servers failed")
          @blocked_mutex.synchronize { @blocked_threads << Thread.current unless @blocked_threads.index(Thread.current) }
          Thread.stop
        end
        retry
      end
    end
  end

  public
  def teardown
    process_pending
    if @data_type == 'channel' and @redis
      @redis.quit
      @redis = nil
    end
  end

end
