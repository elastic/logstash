require "logstash/outputs/base"
require "logstash/namespace"

# send events to a redis databse using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"

  # Name is used for logging in case there are multiple instances.
  # TODO: delete
  config :name, :validate => :string, :default => 'default', 
    :deprecated => true
  
  # The hostname of your redis server.
  config :host, :validate => :string, :default => "127.0.0.1"

  # The port to connect on.
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

    @redis = nil
  end # def register

  private
  def connect
    Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password
    )
  end # def connect

  # A string used to identify a redis instance in log messages
  private
  def identity
    @name || "redis://#{@password}@#{@host}:#{@port}/#{@db} #{@data_type}:#{@key}"
  end


  public
  def receive(event)
    begin
      @redis ||= connect
      if @data_type == 'list'
        @redis.rpush event.sprintf(@key), event.to_json
      else
        @redis.publish event.sprintf(@key), event.to_json
      end
    rescue => e
      @logger.warn(["Failed to log #{event.to_s} to #{identity}.", e])
      raise e
    end
  end # def receive

  public
  def teardown
    if @data_type == 'channel' and @redis
      @redis.quit
      @redis = nil
    end
  end

end
