require "logstash/outputs/base"
require "logstash/namespace"
require "mongo"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"

  config :host, :validate => :string, :required => true
  config :port, :validate => :number
  config :database, :validate => :string, :required => true
  config :collection, :validate => :string, :required => true

  public
  def initialize(params)
    super

    @port ||= Mongo::Connection::DEFAULT_PORT
  end

  public
  def register
    # TODO(petef): support authentication
    # TODO(petef): check for errors
    @mongodb = Mongo::Connection.new(@host, @port).db(@database)
  end # def register

  public
  def receive(event)
    @mongodb.collection(@collection).insert(event.to_hash)
  end # def receive
end # class LogStash::Outputs::Mongodb
