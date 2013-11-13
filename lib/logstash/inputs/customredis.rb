require "logstash/inputs/base"
require "logstash/inputs/threadable"
require "logstash/namespace"

# Read events from a redis. Supports both redis channels and also redis lists
# (using BLPOP)
#
# For more information about redis, see <http://redis.io/>
#
# ## `batch_count` note
#
# If you use the 'batch_count' setting, you *must* use a redis version 2.6.0 or
# newer. Anything older does not support the operations used by batching.
class LogStash::Inputs::Redis < LogStash::Inputs::Threadable
  config_name "customredis"
  milestone 2

  default :codec, "msgpack"

  # Name is used for logging in case there are multiple instances.
  # This feature has no real function and will be removed in future versions.
  config :name, :validate => :string, :default => "default", :deprecated => true

  config :host, :validate => :string, :default => "127.0.0.1"

  config :port, :validate => :number, :default => 6379

  config :db, :validate => :number, :default => 0

  config :timeout, :validate => :number, :default => 5

  config :password, :validate => :password

  config :key, :validate => :string, :required => false, :default => ""

  config :batch_count, :validate => :number, :default => 10

  config :luascript, :validate => :string, :required => true

  public
  def register
    require 'redis'
    @redis = nil
    @redis_url = "redis://#{@password}@#{@host}:#{@port}/#{@db}"
    @data_type = 'list'

    @logger.info("Registering redis", :identity => identity)
  end # def register

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
    load_batch_script(redis)
    return redis
  end # def connect

  private
  def load_batch_script(redis)
    @redis_script_sha = redis.script(:load, @luascript)
  end

  private
  def queue_event(msg, output_queue)
    begin
      @codec.decode(msg) do |event|
        decorate(event)
        output_queue << event
      end
    rescue => e # parse or event creation error
      @logger.error("Failed to create event", :message => msg, :exception => e,
                    :backtrace => e.backtrace);
    end
  end

  private
  def list_listener(redis, output_queue)
    begin
      redis.evalsha(@redis_script_sha, [@key], [@batch_count-1]).each do |item|
        queue_event(item, output_queue)
      end
    rescue Redis::CommandError => e
      if e.to_s =~ /NOSCRIPT/ then
        @logger.warn("Redis may have been restarted, reloading redis batch EVAL script", :exception => e);
        load_batch_script(redis)
        retry
      else
        raise e
      end
    end
  end

  private
  def listener_loop(listener, output_queue)
    while !finished?
      begin
        @redis ||= connect
        self.send listener, @redis, output_queue
      rescue Redis::CannotConnectError => e
        @logger.warn("Redis connection problem", :exception => e)
        sleep 1
        @redis = connect
      rescue => e # redis error
        @logger.warn("Failed to get event from redis", :name => @name,
                     :exception => e, :backtrace => e.backtrace)
        raise e
      end
    end # while !finished?
  end # listener_loop

  public
  def run(output_queue)
    listener_loop :list_listener, output_queue
  end 

end # class LogStash::Inputs::Redis
