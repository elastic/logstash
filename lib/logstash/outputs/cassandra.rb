require "logstash/outputs/base"
require "logstash/namespace"

# Cassandra is a distributed, fault-tolerant key-value store originally created by Facebook, now open source via the Apache group.
# Cassandra is based on Dynamo, but incorporates some BigTable-like ideas, including wide columns and supercolumns.
# Cassandra supports secondary indexes on column values, but the "traditional" way to store timeseries data is by having a
# column-family with wide columns supporting the index, and a separate table holding the events proper.
class LogStash::Outputs::Cassandra < LogStash::Outputs::Base
  config_name "cassandra"
  plugin_status "experimental"

  # A list of nodes and ports in the cluster for our driver to connect to. 
  config :nodes, :validate => :hash, :default => {"localhost" => "9160"}

  # The keyspace where our event data will live.
  config :keyspace, :validate => :string, :default => "logstash"

  # The columnfamily name to write full event records to. The keys will be UUIDs, so if you wish to set key validators or comparators, use UUID.
  config :table, :validate => :string, :default => "logstash"

  # Cassandra rows can have named schema and column types, so you can specify a custom mapping from event fields to Cassandra columns if you want.
  # If not, the @message field goes into a "message" column.
  config :event_schema, :validate => :hash, :default => ["@message", "message"]

  # The columnfamily name(s) to maintain the time-series index in, and the template to use for row keys. 
  # You can specify multiple tables if you want to "index" your events under multiple keys. 
  # The row keys will be run through event.sprintf, so you can bucket the rows by an event attribute.
  #
  # The colum families you list should have a string key, and a UUID comparator for the wide columns:
  #   CREATE COLUMNFAMILY logstash_timeline (id text primary key) WITH comparator=uuid;
  config :index_tables, :validate => :hash

  public
  def register
    require 'cassandra-cql'
    cluster_nodes = @nodes.map { |node, port| "#{node}:#{port}" }

    @logger.info("Cluster nodes", :nodes => cluster_nodes)

    @client = CassandraCQL::Database.new(cluster_nodes, {:keyspace => @keyspace, :cql_version => 3})

    @index_tables ||= {}

    # sanity check.
    ([@table] + @index_tables.keys).each do |t|
      raise "Can't register Cassandra output handler - columnfamily #{t} doesn't exist!" unless @client.schema.column_families.include?(t)
    end

    # Pre-format some values for the CQL statements. Just string manipulation, but since receive gets called on every event, we 
    # want to do the repetitive parts up-front here as the tiny CPU in aggregate adds up to unnecessary load.
    @columns = @event_schema.keys
    @columns_cql_clause = @columns.join(',')
    @column_mappings = @columns.map { |c| @event_schema[c] }.map { |c| "%{#{c}}" }
    @column_mappings_placeholder = (["?"]*@columns.size).join(',')
    @log_insert_query = "INSERT INTO #{@table} (id,#{@columns_cql_clause}) VALUES (?,#{@column_mappings_placeholder})"

    @logger.debug("Will map #{@columns_cql_clause} to #{@column_mappings_cql_clause}")
  end # def register

  protected
  def timestamp_as_uuid(event)
    if RUBY_ENGINE != "jruby"
      event.ruby_timestamp
    else
      Time.at((event.ruby_timestamp.getMillis.to_f/1000).to_i)
    end
  end

  public
  def receive(event)
    return unless output?(event)

    # Generate a type 1 UUID for this event.
    event_uuid = CassandraCQL::UUID.new(self.timestamp_as_uuid(event))

    # Write the event itself. Unfortunately, maintaining the event and index tables don't happen as one atomic transaction; every update is separate.
    column_values = @column_mappings.map do |i|
      if i.eql?('%{@timestamp}')
        self.timestamp_as_uuid(event)
      else
        event.sprintf(i)
      end
    end
    # @logger.info(log_insert_query)
    @client.execute(@log_insert_query, event_uuid, *column_values)

    # Write index maintenance wide columns.
    @index_tables.each do |tbl, id_key|
      timeline_insert_query = "INSERT INTO #{tbl} (id,?) VALUES (?,?)"
      @client.execute(timeline_insert_query, event_uuid, event.sprintf(id_key), '')
    end
  end # def receive
end # class LogStash::Outputs::Cassandra
