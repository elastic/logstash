require "logstash/outputs/base"
require "logstash/namespace"
require 'redis'

class LogStash::Outputs::Redis < LogStash::Outputs::Base

  config_name "redis"

  config :host, :validate => :string, :default => 'localhost'

  config :port, :validate => :number

  config :db, :validate => :number

  config :password, :validate => :string

  config :queue, :validate => :string, :required => true

  def register
    require 'socket'
    @hostname = Socket.gethostname

    opts = {}
    %w{host port db password}.each do |name|
      val = instance_variable_get("@#{name}")
      opts[name.to_sym] = val if val
    end
    @logger.info opts
    @redis = Redis.new(opts)
  end

  def receive(event)
    o = {
      :source_host => @hostname,
      :source => event.source,
      :message => event.message,
      :fields => event.fields,
      :timestamp => event.timestamp,
      :tags => event.tags,
      :type => event.type
    }
    @logger.debug o

    @redis.rpush(event.sprintf(@queue), o.to_json)
  end
end
