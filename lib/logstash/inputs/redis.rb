require "logstash/inputs/base"
require "logstash/namespace"

# Read events from a redis using BLPOP
#
# For more information about redis, see <http://redis.io/>
class LogStash::Inputs::Redis < LogStash::Inputs::Base

  config_name "redis"
  
  # name is used for logging in case there are multiple instances
  config :name, :validate => :string, :default => "default"

  # the hostname of your redis server
  config :host, :validate => :string, :default => "localhost"

  # the port to connect on (optional)
  config :port, :validate => :number

  # The redis database number
  config :db, :validate => :number

  # Timeout of some kind? This isn't really documented in the Redis rubygem
  # docs...
  config :timeout, :validate => :number

  # Password to authenticate with
  config :password, :validate => :password

  # The name of a redis list (we'll use BLPOP against this). Dynamic names are
  # valid here, for example "logstash-%{@type}".  You must specify a list
  # or channel or both.
  config :list, :validate => :string

  # The name of a redis channel (we'll use SUBSCRIBE on this). Dynamic names are
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
    end
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

  def wait command, *args
    begin
      @redis ||= connect
      response = @redis.send(command, *args)
      retries = @retries
      begin
        output_queue << LogStash::Event.new(JSON.parse(response[1]))
      rescue # parse or event creation error
        @logger.error "failed to create event with '#{response[1]}'"
        @logger.error $!
      end
    rescue # redis error
      raise "Redis connection failed too many times" if retries <= 0
      @redis = nil
      @logger.warn "Failed to get event from redis #{@name}. "+
                   "Will retry #{retries} times."
      @logger.warn $!
      retries -= 1
      sleep 1
    end
  end

  def run(output_queue)
    retries = @retries

    if @channel
      Thread.new do
        loop do
          wait :subscribe
        end # loop
      end # Thread.new
    end # if @channel

    if @list
      Thread.new do
        loop do
          wait :blpop, 0
        end # loop
      end # Thread.new
    end # if @list

  end # def run
end # class LogStash::Inputs::Redis
