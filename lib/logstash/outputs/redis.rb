require "logstash/outputs/base"
require "logstash/namespace"

# send events to a redis databse using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"
  
  # Name is used for logging in case there are multiple instances.
  config :name, :validate => :string, :default => 'default'

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

  # The name of a redis list (we'll use RPUSH on this). Dynamic names are
  # valid here, for example "logstash-%{@type}".  You must specify a list
  # or channel or both.
  config :list, :validate => :string

  # The name of a redis channel (we'll use PUBLISH on this). Dynamic names are
  # valid here, for example "logstash-%{@type}".  You must specify a list
  # or channel or both.
  config :channel, :validate => :string

  # Maximum number of retries on a read before we give up.
  config :retries, :validate => :number, :default => 5

  def register
    require 'redis'
    @redis = nil

    unless @list or @channel
      raise "Must specify redis list or channel"
    end # unless @list or @channel
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
      raise "Failed to log to redis #{@name}"
    end

    begin
      @redis ||= connect
      tx = @list and @channel
      @redis.multi if tx
      @redis.rpush event.sprintf(@list), event.to_json if @list
      @redis.publish event.sprintf(@channel), event.to_json if @channel
      @redis.exec if tx
    rescue => e
      # TODO(sissel): Be specific in the exceptions we rescue.
      # Drop the redis connection to be picked up later during a retry.
      @redis = nil
      @logger.warn("Failed to log #{event.to_s} to redis #{@name}. "+
                   "Will retry #{tries} times.")
      @logger.warn($!)
      @logger.debug(["Backtrace", e.backtrace])
      Thread.new do
        sleep 1
        receive(event, tries - 1)
      end
    end
  end # def receive
end
