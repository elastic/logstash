require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"
  plugin_status "beta"

  # your mongodb host
  config :host, :validate => :string, :required => true

  # the mongodb port
  config :port, :validate => :number, :default => 27017

  # The database to use
  config :database, :validate => :string, :required => true

  config :user, :validate => :string, :required => false
  config :password, :validate => :password, :required => false

  # The collection to use. This value can use %{foo} values to dynamically
  # select a collection based on data in the event.
  config :collection, :validate => :string, :required => true

  public
  def register
    require "mongo"
    # TODO(petef): check for errors
    db = Mongo::Connection.new(@host, @port).db(@database)
    auth = true
    if @user then
      auth = db.authenticate(@user, @password.value) if @user
    end
    if not auth then
      raise RuntimeError, "MongoDB authentication failure"
    end
    @mongodb = db
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # TODO(sissel): someone should probably catch errors and retry?

    # the mongodb driver wants time values as a ruby Time object.
    # set the @timestamp value of the document to a ruby Time object, then.
    document = event.to_hash.merge("@timestamp" => event.ruby_timestamp)
    @mongodb.collection(event.sprintf(@collection)).insert(document)
  end # def receive
end # class LogStash::Outputs::Mongodb
