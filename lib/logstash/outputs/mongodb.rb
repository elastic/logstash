require "logstash/outputs/base"
require "logstash/namespace"
require "em-mongo"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"

  public
  def register
    # TODO(sissel): Port?
    # TODO(sissel): Authentication?
    # db and collection are mongodb://.../db/collection
    unused, @db, @collection = @url.path.split("/", 3)
    @mongodb = EventMachine::Mongo::Connection.new(@url.host).db(@db)
  end # def register

  public
  def receive(event)
    @mongodb.collection(@collection).insert(event.to_hash)
  end # def receive
end # class LogStash::Outputs::Mongodb
