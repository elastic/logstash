require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"
  milestone 2

  # a MongoDB URI to connect to
  # See http://docs.mongodb.org/manual/reference/connection-string/
  config :uri, :validate => :string, :required => true
  
  # The database to use
  config :database, :validate => :string, :required => true
   
  # The collection to use. This value can use %{foo} values to dynamically
  # select a collection based on data in the event.
  config :collection, :validate => :string, :required => true

  # If true, store the @timestamp field in mongodb as an ISODate type instead
  # of an ISO8601 string.  For more information about this, see
  # http://www.mongodb.org/display/DOCS/Dates
  config :isodate, :validate => :boolean, :default => false

  # Number of seconds to wait after failure before retrying
  config :retry_delay, :validate => :number, :default => 3, :required => false

  # If true, a _id field will be added to the document before insertion.
  # The _id field will use the timestamp of the event and overwrite an existing
  # _id field in the event.
  config :generateId, :validate => :boolean, :default => false

  public
  def register
    require "mongo"
    uriParsed=Mongo::URIParser.new(@uri)
    conn = uriParsed.connection({})
    if uriParsed.auths.length > 0
      uriParsed.auths.each do |auth|
        conn.add_auth(auth['db_name'], auth['username'], auth['password'])
      end
      conn.apply_saved_authentication()
    end
    @db = conn.db(@database)
  end # def register

  public
  def receive(event)
    return unless output?(event)

    begin
      if @isodate
        # the mongodb driver wants time values as a ruby Time object.
        # set the @timestamp value of the document to a ruby Time object, then.
        document = event.to_hash
      else
        document = event.to_hash.merge("@timestamp" => event["@timestamp"].to_json)
      end
      if @generateId
        document['_id'] = BSON::ObjectId.new(nil, event.ruby_timestamp)
      end
      @db.collection(event.sprintf(@collection)).insert(document)
    rescue => e
      @logger.warn("Failed to send event to MongoDB", :event => event, :exception => e,
                   :backtrace => e.backtrace)
      if e.error_code == 11000
          # On a duplicate key error, skip the insert.
          # We could check if the duplicate key err is the _id key
          # and generate a new primary key.
          # If the duplicate key error is on another field, we have no way
          # to fix the issue.
      else
        sleep @retry_delay
        retry
      end
    end
  end # def receive
end # class LogStash::Outputs::Mongodb
