require "logstash/inputs/base"
require "logstash/namespace"
require "em-redis"

class LogStash::Inputs::Redis < LogStash::Inputs::Base
  public
  def initialize(url, config={}, &block)
    super
  end

  def register
    _, @db, @queue = @url.path.split('/')
    puts @url.host, @url.port, @db, @queue
    EM.run do
      redis = EM::Protocols::Redis.connect :host => @url.host, :port => @url.port, :db => @db
      pop = lambda do
        redis.blpop @queue, 0 do |response|
          event = LogStash::Event.new({
            "@message" => response,
            "@type" => @type,
            "@tags" => @tags.clone,
          })
          event.source = @url
          @callback.call(event)
          pop.call
        end
      end
      pop.call
    end
  end
end
