require "logstash/inputs/base"
require "logstash/namespace"
require "redis"

class LogStash::Inputs::Redis < LogStash::Inputs::Base

  config_name "redis"
  
  # name is used for logging in case there are multiple instances
  config :name, :validate => :string, :default => 'default'

  config :host, :validate => :string

  config :port, :validate => :number

  config :db, :validate => :number

  config :timeout, :validate => :number

  config :password, :validate => :password

  config :queue, :validate => :string, :required => true

  config :retries, :validate => :number, :default => 5

  def register
    @redis = nil
  end

  def connect
    require 'redis'
    Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password
    )
  end

  def run output_queue
    Thread.new do
      LogStash::Util::set_thread_name("input|redis|#{@queue}")
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
      end
    end
  end
end
