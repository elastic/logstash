require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"

  # your mongdob host
  config :host, :validate => :string, :required => true

  # the mongodb port
  config :port, :validate => :number, :default => 27017

  # The database to use
  config :database, :validate => :string, :required => true

  # The collection to use. This value can use %{foo} values to dynamically
  # select a collection based on data in th eevent.
  config :collection, :validate => :string, :required => true

  public
  def register
    require "mongo"
    # TODO(petef): support authentication
    # TODO(petef): check for errors
    @mongodb = Mongo::Connection.new(@host, @port).db(@database)
  end # def register

  public
  def receive(event)
    @mongodb.collection(event.sprintf(@collection)).insert(event.to_hash)
  end # def receive
end # class LogStash::Outputs::Mongodb
