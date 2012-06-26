require "logstash/outputs/base"
require "logstash/namespace"

# Riak is a distributed k/v store from Basho.
# It's based on the Dynamo model.

class LogStash::Outputs::Riak < LogStash::Outputs::Base
  config_name "riak"
  plugin_status "experimental"

  # The nodes of your Riak cluster
  # This can be a single host or
  # a Logstash hash of node/port pairs
  # e.g
  # ["node1", "8098", "node2", "8098"]
  config :nodes, :validate => :hash, :default => {"localhost" =>  "8098"}

  # The protocol to use
  # HTTP or ProtoBuf
  # Applies to ALL backends listed above
  # No mix and match
  config :proto, :validate => ["http", "pb"], :default => "http"

  # The bucket name to write events to
  # Expansion is supported here as values are 
  # passed through event.sprintf
  config :bucket, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The event key name
  # variables are valid here.
  #
  # Choose this carefully. Best to let riak decide....
  config :key_name, :validate => :string


  # Quorum options (NYI)
  # Logstash hash of options for various quorum parameters
  # i.e.
  # `quorum => ["r", "1", "w", "1", "dw", "1"]`
  config :quorum, :validate => :array, :default => {"r" => 1, "w" => 1, "dw" => 1}

  # Indices
  # Array of fields to add 2i on
  # e.g.
  # `indices => ["@source_host", "@type"]
  # Off by default as not everyone runs eleveldb
  config :indices, :validate => :array

  # Search (NYI)
  # Enable search on the bucket defined above
  config :enable_search, :validate => :boolean, :default => false

  public
  def register
    require 'riak'
    cluster_nodes = Array.new
    @logger.debug("Setting protocol", :protocol => @proto)
    proto_type = "#{@proto}_port".to_sym
    @nodes.each do |node,port|
      @logger.debug("Adding node", :node => node, :port => port)
      cluster_nodes << {:host => node, proto_type => port}
    end
    @logger.debug("Cluster nodes", :nodes => cluster_nodes)
    @client = Riak::Client.new(:nodes => cluster_nodes)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    
    # setup our bucket
    bukkit = @client.bucket(event.sprintf(@bucket))
    @logger.debug("Bucket", :bukkit => bukkit.to_s)
    
    @key_name.nil? ? evt_key=nil : evt_key=event.sprintf(@key_name)
    evt = Riak::RObject.new(bukkit, evt_key)
    @logger.debug("RObject", :robject => evt.to_s)
    begin
      evt.content_type = "application/json"
      evt.data = event
      if @indices
        @indices.each do |k|
          idx_name = "#{k.gsub('@','')}_bin"
          @logger.debug("Riak index name", :idx => idx_name)
          @logger.info("Indexes", :indexes => evt.indexes.to_s)
          evt.indexes[idx_name] << event.sprintf("%{#{k}}")
        end
      end
      evt.store
    rescue Exception => e
      @logger.warn("Exception storing", :message => e.message)
    end
  end # def receive
end # class LogStash::Outputs::Riak
