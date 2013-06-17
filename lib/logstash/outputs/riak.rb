require "logstash/outputs/base"
require "logstash/namespace"

# Riak is a distributed k/v store from Basho.
# It's based on the Dynamo model.

class LogStash::Outputs::Riak < LogStash::Outputs::Base
  config_name "riak"
  milestone 1

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
  # Multiple buckets can be specified here
  # but any bucket-specific settings defined
  # apply to ALL the buckets.
  config :bucket, :validate => :array, :default => ["logstash-%{+YYYY.MM.dd}"]

  # The event key name
  # variables are valid here.
  #
  # Choose this carefully. Best to let riak decide....
  config :key_name, :validate => :string

  # Bucket properties (NYI)
  # Logstash hash of properties for the bucket
  # i.e.
  # `bucket_props => ["r", "one", "w", "one", "dw", "one"]`
  # or
  # `bucket_props => ["n_val", "3"]`
  # Note that the Logstash config language cannot support
  # hash or array values
  # Properties will be passed as-is
  config :bucket_props, :validate => :hash

  # Indices
  # Array of fields to add 2i on
  # e.g.
  # `indices => ["@source_host", "@type"]
  # Off by default as not everyone runs eleveldb
  config :indices, :validate => :array

  # Search
  # Enable search on the bucket defined above
  config :enable_search, :validate => :boolean, :default => false

  # SSL
  # Enable SSL
  config :enable_ssl, :validate => :boolean, :default => false

  # SSL Options
  # Options for SSL connections
  # Only applied if SSL is enabled
  # Logstash hash that maps to the riak-client options
  # here: https://github.com/basho/riak-ruby-client/wiki/Connecting-to-Riak
  # You'll likely want something like this:
  # `ssl_opts => ["pem", "/etc/riak.pem", "ca_path", "/usr/share/certificates"]
  # Per the riak client docs, the above sample options
  # will turn on SSL `VERIFY_PEER`
  config :ssl_opts, :validate => :hash

  # Metadata (NYI)
  # Allow the user to set custom metadata on the object
  # Should consider converting logstash data to metadata as well
  #

  public
  def register
    require 'riak'
    riak_opts = {}
    cluster_nodes = Array.new
    @logger.debug("Setting protocol", :protocol => @proto)
    proto_type = "#{@proto}_port".to_sym
    @nodes.each do |node,port|
      @logger.debug("Adding node", :node => node, :port => port)
      cluster_nodes << {:host => node, proto_type => port}
    end
    @logger.debug("Cluster nodes", :nodes => cluster_nodes)
    if @enable_ssl
      @logger.debug("SSL requested")
      if @ssl_opts
        @logger.debug("SSL options provided", @ssl_opts)
        riak_opts.merge!(@ssl_opts.inject({}) {|h,(k,v)| h[k.to_sym] = v; h})
      else
        riak_opts.merge!({:ssl => true})
      end
    @logger.debug("Riak options:", :riak_opts => riak_opts)
    end
    riak_opts.merge!({:nodes => cluster_nodes})
    @logger.debug("Riak options:", :riak_opts => riak_opts)
    @client = Riak::Client.new(riak_opts)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    
    @bucket.each do |b|
      # setup our bucket(s)
      bukkit = @client.bucket(event.sprintf(b))
      # Disable bucket props for now
      # Need to detect params passed that should be converted to int
      # otherwise setting props fails =(
      # Logstash syntax only supports strings and bools
      # likely fix is to either hack in is_numeric?
      # or whitelist certain params and call to_i
      ##@logger.debug("Setting bucket props", :props => @bucket_props)
      ##bukkit.props = @bucket_props if @bucket_props
      ##@logger.debug("Bucket", :bukkit => bukkit.inspect)
     
      if @enable_search
        @logger.debug("Enable search requested", :bucket => bukkit.inspect)
        # Check if search is enabled
        @logger.debug("Checking bucket status", :search_enabled => bukkit.is_indexed?)
        bukkit.enable_index! unless bukkit.is_indexed?
        @logger.debug("Rechecking bucket status", :search_enabled => bukkit.is_indexed?)
      end
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
    end
  end # def receive
end # class LogStash::Outputs::Riak
