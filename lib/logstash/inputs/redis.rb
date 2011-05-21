require "logstash/inputs/base"
require "logstash/namespace"

# Read events from a redis using BLPOP
#
# For more information about redis, see <http://redis.io/>
class LogStash::Inputs::Redis < LogStash::Inputs::Base

  config_name "redis"
  
  # Name is used for logging in case there are multiple instances.
  config :name, :validate => :string, :default => "default"

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
  config :queue, :validate => :string, :required => true

  # Maximum number of retries on a read before we give up.
  config :retries, :validate => :number, :default => 5

  public
  def initialize(params)
    super

    @format ||= ["json_event"]
  end # def initialize

  public
  def register
    require 'redis'
    @redis = nil
    @redis_url = "redis://#{@password}@#{@host}:#{@port}/#{@db}"
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

  public
  def run(output_queue)
    retries = @retries
    loop do
      begin
        @redis ||= connect
        response = @redis.blpop @queue, 0
        retries = @retries
        e = to_event(response[1], @redis_url)
        if e
          output_queue << e
        end
      rescue # redis error
        if retries <= 0
          raise RuntimeError, "Redis connection failed too many times"
        end
        @redis = nil
        @logger.warn(["Failed to get event from redis #{@name}. " +
                      "Will retry #{retries} times.", $!])
        retries -= 1
        sleep(1)
      end
    end # loop
  end # def run
end # class LogStash::Inputs::Redis
