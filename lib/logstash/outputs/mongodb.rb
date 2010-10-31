require "logstash/outputs/base"
require "em-mongo"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base
  def initialize(url, config={}, &block)
    super
  end

  def register
    # Port?
    # Authentication?
    db = @url.path[1..-1] # Skip leading '/'
    @mongodb = EventMachine::Mongo::Connection.new(@url.host).db(db)
  end # def register

  def receive(event)
    @mongodb.collection("events").insert(event.to_hash)
  end # def event
end # class LogStash::Outputs::Mongodb
