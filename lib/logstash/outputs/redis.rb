require "logstash/outputs/base"
require "logstash/namespace"
require 'eventmachine'

# send events to a redis databse using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"
  
  # Name is used for logging in case there are multiple instances.
  config :name, :validate => :string, :default => 'default'

  # The hostname of your redis server.  Hostname is 127.0.0.1 by default.
  config :host, :validate => :string

  # The port to connect on.  Port is 6379 by default.
  config :port, :validate => :number

  # The redis database number.  Db is 0 by default.
  config :db, :validate => :number

  # Redis initial connection timeout in seconds.  Timeout is 5 seconds by
  # default.
  config :timeout, :validate => :number

  # Password to authenticate with.  There is no authentication by default.
  config :password, :validate => :password

  # The name of the redis queue (we'll use RPUSH on this). Dynamic names are
  # valid here, for example "logstash-%{@type}"
  config :queue, :validate => :string, :required => true

  # Maximum number of retries on a read before we give up.
  config :retries, :validate => :number, :default => 5

  def register
    require 'redis'
    @redis = nil
  end # def register

  def connect
    Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password
    )
  end # def connect

  def receive(event, tries=@retries)
    if tries <= 0
      @logger.error "Fatal error, failed to log #{event.to_s} to redis #{@name}"
      raise RuntimeError.new "Failed to log to redis #{@name}"
    end

    begin
      @redis ||= connect
      @redis.rpush event.sprintf(@queue), event.to_json
    rescue
      # TODO(sissel): Be specific in the exceptions we rescue.
      # Drop the redis connection to be picked up later during a retry.
      @redis = nil
      @logger.warn "Failed to log #{event.to_s} to redis #{@name}. "+
                   "Will retry #{tries} times."
      @logger.warn $!
      Thread.new do
        sleep 1
        receive event, tries - 1
      end
    end
  end # def receive
end
