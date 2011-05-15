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

  def run(output_queue)
    wait = Proc.new do |command, *args|
      retries = @retries
      begin
        @redis ||= connect
        response = nil
        if command == :subscribe
          @redis.send(:subscribe, *args) do |on|
            on.message do |c, r|
              response = r
            end
          end
        else
          response = @redis.send(command, *args)
        end
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
        @logger.warn $!.backtrace
        retries -= 1
        sleep 1
        retry
      end
    end

    if @channel
      Thread.new do
        loop do
          retries = @retries
          begin
            @redis ||= connect
            @redis.subscribe @channel do |on|
              on.subscribe do |ch, count|
                @logger.debug "Subscribed to #{ch} (#{count})"
                retries = @retries
              end

              on.message do |ch, message|
                begin
                  output_queue << LogStash::Event.new(JSON.parse(message))
                rescue # parse or event creation error
                  @logger.error "Failed to create event with '#{message}'"
                  @logger.error $!
                  @logger.error $!.backtrace
                end
              end

              on.unsubscribe do |ch, count|
                @logger.debug "Unsubscribed from #{ch} (#{count})"
              end
            end
          rescue # redis error
            raise "Redis connection failed too many times" if retries <= 0
            @redis = nil
            @logger.warn "Failed to get event from redis #{@name}. "+
                         "Will retry #{retries} times."
            @logger.warn $!
            @logger.warn $!.backtrace
            retries -= 1
            sleep 1
            retry
          end
        end # loop
      end # Thread.new
    end # if @channel

    if @list
      Thread.new do
        loop do
          retries = @retries
          begin
            @redis ||= connect
            response = @redis.blpop @list, 0
            retries = @retries
            begin
              output_queue << LogStash::Event.new(JSON.parse(response[1]))
            rescue # parse or event creation error
              @logger.error "failed to create event with '#{response[1]}'"
              @logger.error $!
              @logger.error $!.backtrace
            end
          rescue # redis error
            raise "Redis connection failed too many times" if retries <= 0
            @redis = nil
            @logger.warn "Failed to get event from redis #{@name}. "+
                         "Will retry #{retries} times."
            @logger.warn $!
            @logger.warn $!.backtrace
            retries -= 1
            sleep 1
            retry
          end
        end # loop
      end # Thread.new
    end # if @list

  end # def run
end # class LogStash::Inputs::Redis
