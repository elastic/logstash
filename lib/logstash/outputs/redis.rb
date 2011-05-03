require "logstash/outputs/base"
require "logstash/namespace"
require 'em-redis'

class LogStash::Outputs::Redis < LogStash::Outputs::Base

  def register
    @port = nil
    @password = nil
    @host = @url.host
    _, @db, @queue = @url.path.split('/')
    require 'socket'
    @hostname = Socket.gethostname
    @work = []
    @redis = EM::Protocols::Redis.connect({
      :host => @host, 
      :port => @port, 
      :db => @db
    })
    end

  def receive(event)
    @redis.rpush(event.sprintf(@queue), {
      :source_host => @hostname, 
      :source => event.source,
      :message => event.message
    }.to_json)
  end
end
