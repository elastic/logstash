require "logstash/inputs/base"
require "logstash/inputs/threadable"
require "logstash/namespace"

# Read events from a redis. Supports both redis channels and also redis lists
# (using BLPOP)
#
# For more information about redis, see <http://redis.io/>
class LogStash::Inputs::Redis < LogStash::Inputs::Threadable

  config_name "redis"
  plugin_status "beta"

  # Name is used for logging in case there are multiple instances.
  # This feature has no real function and will be removed in future versions.
  config :name, :validate => :string, :default => "default", :deprecated => true

  # The hostname of your redis server.
  config :host, :validate => :string, :default => "127.0.0.1"

  # The port to connect on.
  config :port, :validate => :number, :default => 6379

  # The redis database number.
  config :db, :validate => :number, :default => 0

  # Initial connection timeout in seconds.
  config :timeout, :validate => :number, :default => 5

  # Password to authenticate with. There is no authentication by default.
  config :password, :validate => :password

  # The name of the redis queue (we'll use BLPOP against this).
  # TODO: remove soon.
  config :queue, :validate => :string, :deprecated => true

  # The name of a redis list or channel.
  # TODO: change required to true
  config :key, :validate => :string, :required => false

  # Either list or channel.  If redis\_type is list, then we will BLPOP the
  # key.  If redis\_type is channel, then we will SUBSCRIBE to the key.
  # If redis\_type is pattern_channel, then we will PSUBSCRIBE to the key.
  # TODO: change required to true
  config :data_type, :validate => [ "list", "channel", "pattern_channel" ], :required => false

  # How many events to return from redis using EVAL
  config :batch_count, :validate => :number, :default => 1

  # How many pipelined requests to do against redis
  # Each request uses EVAL to fetch upto batch_count events if batch_count is > 1
  config :pipeline_count, :validate => :number, :default => 1

  public
  def initialize(params)
    super

    @format ||= "json_event"
  end # def initialize

  public
  def register
    require 'redis'
    @redis = nil
    @redis_url = "redis://#{@password}@#{@host}:#{@port}/#{@db}"

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

    @logger.info("Registering redis", :identity => identity)
  end # def register

  # A string used to identify a redis instance in log messages
  # TODO(sissel): Use instance variables for this once the @name config
  # option is removed.
  private
  def identity
    @name || "#{@redis_url} #{@data_type}:#{@key}"
  end

  private
  def connect
    redis = Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password.nil? ? nil : @password.value
    )
    load_batch_script(redis) if @data_type == 'list' && (@batch_count > 1 || @pipeline_count > 1)
    return redis
  end # def connect

  private
  def load_batch_script(redis)
    #A redis lua EVAL script to fetch a count of keys
    #in case count is bigger than current items in queue whole queue will be returned without extra nil values
    redis_script = <<EOF
          local i = tonumber(ARGV[1])
          local res = {}
          local length = redis.call('llen',KEYS[1])
          if length < i then i = length end
          while (i > 0) do
            table.insert(res, redis.call('lpop',KEYS[1]))
            i = i-1
          end
          return res
EOF
    @redis_script_sha = redis.script(:load, redis_script)
  end

  private
  def queue_event(msg, output_queue)
    begin
      event = to_event msg, identity
      output_queue << event if event
    rescue => e # parse or event creation error
      @logger.error("Failed to create event", :message => msg, :exception => e,
                    :backtrace => e.backtrace);
    end
  end

  private
  def list_listener(redis, output_queue)
    response = redis.blpop @key, 0
    queue_event response[1], output_queue

    if @batch_count > 1 || @pipeline_count > 1
      begin
        redis.pipelined do
          @pipeline_count.times do
            @batch_count > 1 ? redis.evalsha(@redis_script_sha, [@key], [@batch_count]) : redis.lpop(@key)
          end
        end.flatten(1).each do |message|
          queue_event message, output_queue if message
        end
      rescue Redis::CommandError => e
        if e.to_s =~ /NOSCRIPT/ then
          @logger.warn("Redis must have been restarted, reloading redis batch EVAL script", :exception => e);
          load_batch_script(redis)
          retry
        else
          raise e
        end
      end
    end
  end

  private
  def channel_listener(redis, output_queue)
    redis.subscribe @key do |on|
      on.subscribe do |channel, count|
        @logger.info("Subscribed", :channel => channel, :count => count)
      end

      on.message do |channel, message|
        queue_event message, output_queue
      end

      on.unsubscribe do |channel, count|
        @logger.info("Unsubscribed", :channel => channel, :count => count)
      end
    end
  end

  private
  def pattern_channel_listener(redis, output_queue)
    redis.psubscribe @key do |on|
      on.psubscribe do |channel, count|
        @logger.info("Subscribed", :channel => channel, :count => count)
      end

      on.pmessage do |ch, event, message|
        queue_event message, output_queue
      end

      on.punsubscribe do |channel, count|
        @logger.info("Unsubscribed", :channel => channel, :count => count)
      end
    end
  end

  # Since both listeners have the same basic loop, we've abstracted the outer
  # loop.
  private
  def listener_loop(listener, output_queue)
    while !finished?
      begin
        @redis ||= connect
        self.send listener, @redis, output_queue
      rescue => e # redis error
        @logger.warn("Failed to get event from redis", :name => @name,
                     :exception => e, :backtrace => e.backtrace)
        raise e
      end
    end # while !finished?
  end # listener_loop

  public
  def run(output_queue)
    if @data_type == 'list'
      listener_loop :list_listener, output_queue
    elsif @data_type == 'channel'
      listener_loop :channel_listener, output_queue
    else
      listener_loop :pattern_channel_listener, output_queue
    end
  end # def run

  public
  def teardown
    if @data_type == 'channel' and @redis
      @redis.unsubscribe
      @redis.quit
      @redis = nil
    end
    if @data_type == 'pattern_channel' and @redis
      @redis.punsubscribe
      @redis.quit
      @redis = nil
    end
    finished
  end
end # class LogStash::Inputs::Redis
