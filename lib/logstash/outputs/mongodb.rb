require "logstash/namespace"
require "logstash/event"
require "uri"
require "em-mongo"

class LogStash::Outputs::Mongodb
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String
    @config = config
  end

  def register
    # Port?
    # Authentication?
    db = @url.path[1..-1] # Skip leading '/'
    @mongodb = EventMachine::Mongo::Connection.new(@url.host).db(db)
  end # def register

  def receive(event)
    puts "Got: #{event}"
    @mongodb.collection("events").insert(event.to_hash)
  end # def event
end # class LogStash::Outputs::Websocket
