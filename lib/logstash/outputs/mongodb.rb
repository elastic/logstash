require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Mongodb < LogStash::Outputs::Base

  config_name "mongodb"
  plugin_status "beta"

  # your mongodb host set required to false as we arn't using it.
  config :host, :validate => :string, :required => false

  # the mongodb port
  config :port, :validate => :number, :default => 27017

  # The database to use
  config :database, :validate => :string, :required => true

  config :user, :validate => :string, :required => false
  config :password, :validate => :password, :required => false

  # The collection to use. This value can use %{foo} values to dynamically
  # select a collection based on data in the event.
  config :collection, :validate => :string, :required => true
  
  # MongoDB replica set support configuration.
  # The mongodb hosts array. This configuration is in the format of an array "['host1:port','host2:port','host3:port']"
  config :hosts, :validate => :array, :required => false

  # We now need to know if we are using a replica set or not.
  config :replicaset, :validate => :boolean, :required => false

  # The interval between checks to see if the replica set has changed.
  config :replicaset_refresh_interval, :validate => :number, :required => false
  
  # Periodically update the state of the connection every replicaset_refresh_interval seconds
  config :replicaset_refresh_mode, :validate => :boolean, :required => false

  public
  def register
    require "mongo"
    # TODO(petef): check for errors
	if @replicaset then
		if @replicaset_refresh_mode then
			if @replicaset_refresh_interval then
				@conn = Mongo::ReplSetConnection.new(hosts, :refresh_interval => @replicaset_refresh_interval, :refresh_mode => :sync)
			else
				@conn = Mongo::ReplSetConnection.new(hosts, :refresh_mode => :sync)
			end
		else
			@conn = Mongo::ReplSetConnection.new(hosts)
		end
	else
		@conn = Mongo::Connection.new(@host, @port)
	end
      auth = true
      if @user then
       	@conn.add_auth(@database, @user, @password.value)
       	auth = @conn.apply_saved_authentication() 
       	@coll = @conn.db(@database).collection(@collection)
      end
      if not auth then
        raise RuntimeError, "MongoDB authentication failure"
      end
    end # def register

  public
  def receive(event)
    return unless output?(event)

    @coll.insert(event.to_hash)
  end # def receive
end # class LogStash::Outputs::Mongodb