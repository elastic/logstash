require "logstash/outputs/base"
require "logstash/namespace"

# send events to a redis databse using RPUSH
#
# For more information about redis, see <http://redis.io/>
class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"
  
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

  # The name of a redis list or channel. Dynamic names are
  # valid here, for example "logstash-%{@type}".
  config :key, :validate => :string, :required => true

  # Either list or channel.  If redis_type is list, then we will RPUSH to key.
  # If redis_type is channel, then we will PUBLISH to key.
  config :data_type, :validate => [ "list", "channel" ], :required => true

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

  # A string used to identify a redis instance in log messages
  def identity
    "redis://#{@password}@#{@host}:#{@port}/#{@db} #{@data_type}:#{@key}"
  end


  def receive(event, tries=@retries)
    if tries <= 0
      @logger.error "Fatal error, failed to log #{event.to_s} to #{identity}"
      raise RuntimeError, "Failed to log to #{identity} after #{@retries} tries"
    end

    begin
      @redis ||= connect
      if @data_type == 'list'
        @redis.rpush event.sprintf(@key), event.to_json
      else
        @redis.publish event.sprintf(@key), event.to_json
      end
    rescue => e
      # TODO(sissel): Be specific in the exceptions we rescue.
      # Drop the redis connection to be picked up later during a retry.
      @redis = nil
      @logger.warn(["Failed to log #{event.to_s} to #{identity}. " +
                   "Will retry #{retries} times.", $!])
      @logger.debug(["Backtrace", e.backtrace])
      Thread.new do
        sleep 1
        receive(event, tries - 1)
      end
    end
  end # def receive
end
