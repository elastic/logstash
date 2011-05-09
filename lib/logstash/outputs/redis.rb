require "logstash/outputs/base"
require "logstash/namespace"
require 'eventmachine'

class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"
  
  # name is used for logging in case there are multiple instances
  config :name, :validate => :string, :default => 'default'

  # the hostname of your redis server
  config :host, :validate => :string

  # the port to connect on (optional)
  config :port, :validate => :number

  # The redis database number
  config :db, :validate => :number

  # Timeout of some kind? This isn't really documented in the Redis rubygem
  # docs...
  config :timeout, :validate => :number

  # Password to authenticate with
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
