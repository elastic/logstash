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

  # If true, store the @timestamp field in mongodb as an ISODate type instead
  # of an ISO8601 string.  For more information about this, see
  # http://www.mongodb.org/display/DOCS/Dates
  config :isodate, :validate => :boolean, :default => false

  # Number of seconds to wait after failure before retrying
  config :retry_delay, :validate => :number, :default => 3, :required => false

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

    begin
      if @isodate
        # the mongodb driver wants time values as a ruby Time object.
        # set the @timestamp value of the document to a ruby Time object, then.
        document = event.to_hash.merge("@timestamp" => event.ruby_timestamp)
        @mongodb.collection(event.sprintf(@collection)).insert(document)
      else
        @mongodb.collection(event.sprintf(@collection)).insert(event.to_hash)
      end
    rescue => e
      @logger.warn("Failed to send event to MongoDB", :event => event, :exception => e,
                   :backtrace => e.backtrace)
      sleep @retry_delay
      retry
    end
  end # def receive
end # class LogStash::Outputs::Mongodb
