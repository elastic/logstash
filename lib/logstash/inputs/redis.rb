require "logstash/inputs/base"
require "logstash/namespace"

# Read events from a redis using BLPOP
#
# For more information about redis, see <http://redis.io/>
class LogStash::Inputs::Redis < LogStash::Inputs::Base

  config_name "redis"
  
  # Name is used for logging in case there are multiple instances.
  config :name, :validate => :string, :default => "default"

  # The hostname of your redis server.  Default hostname is 127.0.0.1.
  config :host, :validate => :string

  # The port to connect on.  The default port is 6379.
  config :port, :validate => :number

  # The redis database number.  Db is 0 by default.
  config :db, :validate => :number

  # Initial connection timeout in seconds.  Default timeout is 5 seconds.
  config :timeout, :validate => :number

  # Password to authenticate with.  There is no authentication by default.
  config :password, :validate => :password

  # The name of the redis queue (we'll use BLPOP against this).
  config :queue, :validate => :string, :required => true

  # Maximum number of retries on a read before we give up.
  config :retries, :validate => :number, :default => 5

  def register
    require 'redis'
    @redis = nil
  end

  def connect
    Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password
    )
  end

  def run(output_queue)
    retries = @retries
    loop do
      begin
        @redis ||= connect
        response = @redis.blpop @queue, 0
        retries = @retries
        begin
          output_queue << LogStash::Event.new(JSON.parse(response[1]))
        rescue # parse or event creation error
          @logger.error "failed to create event with '#{response[1]}'"
          @logger.error $!
        end
      rescue # redis error
        raise RuntimeError.new "Redis connection failed too many times" if retries <= 0
        @redis = nil
        @logger.warn "Failed to get event from redis #{@name}. "+
                     "Will retry #{retries} times."
        @logger.warn $!
        retries -= 1
        sleep 1
      end
    end # loop
  end # def run
end # class LogStash::Inputs::Redis
