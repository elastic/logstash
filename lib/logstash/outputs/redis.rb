require "logstash/outputs/base"
require "logstash/namespace"
require 'eventmachine'

class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"
  
  # name is used for logging in case there are multiple instances
  config :name, :validate => :string, :default => 'default'

  config :host, :validate => :string

  config :port, :validate => :number

  config :db, :validate => :number

  config :timeout, :validate => :number

  config :password, :validate => :password

  config :queue, :validate => :string, :required => true

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

  def receive event, tries=5
    if tries > 0
      begin
        @redis ||= connect
        @redis.rpush event.sprintf(@queue), event.to_json
      rescue
        @redis = nil
        @logger.warn "Failed to log #{event.to_s} to redis #{@name}. "+
                     "Will retry #{tries} times."
        @logger.warn $!
        Thread.new do
          sleep 1
          receive event, tries - 1
        end
      end
    else
      @logger.error "Fatal error, failed to log #{event.to_s} to redis #{@name}"
      raise RuntimeError.new "Failed to log to redis #{@name}"
    end
  end
end
