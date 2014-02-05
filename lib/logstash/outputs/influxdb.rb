# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"
require "stud/buffer"

# This output lets you output Metrics to InfluxDB
#
# The configuration here attempts to be as friendly as possible
# and minimize the need for multiple definitions to write to
# multiple series and still be efficient
#
# the InfluxDB API let's you do some semblance of bulk operation
# per http call but each call is database-specific
#
# You can learn more about InfluxDB at <http://influxdb.org>
class LogStash::Outputs::InfluxDB < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "influxdb"
  milestone 1

  # The database to write
  config :db, :validate => :string, :default => "stats"

  # The hostname or IP address to reach your InfluxDB instance
  config :host, :validate => :string, :required => true

  # The port for InfluxDB
  config :port, :validate => :number, :default => 8086

  # The user who has access to the named database
  config :user, :validate => :string, :default => nil, :required => true

  # The password for the user who access to the named database
  config :password, :validate => :password, :default => nil, :required => true

  # Series name - supports sprintf formatting
  config :series, :validate => :string, :default => "logstash"

  # Hash of key/value pairs representing data points to send to the named database
  # Example: `{'column1' => 'value1', 'column2' => 'value2'}`
  #
  # Events for the same series will be batched together where possible
  # Both keys and values support sprintf formatting
  config :data_points, :validate => :hash, :default => {}, :required => true

  # Allow the override of the `time` column in the event?
  #
  # By default any column with a name of `time` will be ignored and the time will
  # be determined by the value of `@timestamp`.
  #
  # Setting this to `true` allows you to explicitly set the `time` column yourself
  #
  # Note: **`time` must be an epoch value in either seconds, milliseconds or microseconds**
  config :allow_time_override, :validate => :boolean, :default => false

  # Set the level of precision of `time`
  #
  # only useful when overriding the time value
  config :time_precision, :validate => ["m", "s", "u"], :default => "s"

  # Allow value coercion
  #
  # this will attempt to convert data point values to the appropriate type before posting
  # otherwise sprintf-filtered numeric values could get sent as strings
  # format is `{'column_name' => 'datatype'}
  #
  # currently supported datatypes are integer and float
  #
  config :coerce_values, :validate => :hash, :default => {}

  # This setting controls how many events will be buffered before sending a batch
  # of events. Note that these are only batched for the same series
  config :flush_size, :validate => :number, :default => 100

  # The amount of time since last flush before a flush is forced.
  #
  # This setting helps ensure slow event rates don't get stuck in Logstash.
  # For example, if your `flush_size` is 100, and you have received 10 events,
  # and it has been more than `idle_flush_time` seconds since the last flush,
  # logstash will flush those 10 events automatically.
  #
  # This helps keep both fast and slow log streams moving along in
  # near-real-time.
  config :idle_flush_time, :validate => :number, :default => 1

  public
  def register
    require "ftw" # gem ftw
    require 'cgi'
    @agent = FTW::Agent.new
    @queue = []

    @query_params = "u=#{@user}&p=#{@password.value}&time_precision=#{@time_precision}"
    @base_url = "http://#{@host}:#{@port}/db/#{@db}/series"
    @url = "#{@base_url}?#{@query_params}"
    
    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register
  
  public
  def receive(event)
    return unless output?(event)

    # A batch POST for InfluxDB looks like this:
    # [
    #   {
    #     "name": "events",
    #     "columns": ["state", "email", "type"],
    #     "points": [
    #       ["ny", "paul@influxdb.org", "follow"],
    #       ["ny", "todd@influxdb.org", "open"]
    #     ]
    #   },
    #   {
    #     "name": "errors",
    #     "columns": ["class", "file", "user", "severity"],
    #     "points": [
    #       ["DivideByZero", "example.py", "someguy@influxdb.org", "fatal"]
    #     ]
    #   }
    # ]
    event_hash = {}
    event_hash['name'] = event.sprintf(@series)
    sprintf_points = Hash[@data_points.map {|k,v| [event.sprintf(k), event.sprintf(v)]}]
    if sprintf_points.has_key?('time')
      @logger.error("Cannot override value of time without 'allow_override_time'. Using event timestamp") unless @allow_override_time
    else
      sprintf_points['time'] = to_epoch(event.timestamp)
    end
    @coerce_values.each do |column, value_type|
      if sprintf_points.has_key?(column)
        begin
          case value_type
          when "integer"
            @logger.debug("Converting column #{column} to type #{value_type}: Current value: #{sprintf_points[column]}")
            sprintf_points[column] = sprintf_points[column].to_i
          when "float"
            @logger.debug("Converting column #{column} to type #{value_type}: Current value: #{sprintf_points[column]}")
            sprintf_points[column] = sprintf_points[column].to_f
          else
            @logger.error("Don't know how to convert to #{value_type}")
          end
        rescue => e
          @logger.error("Unhandled exception", :error => e.message)
        end
      end
    end
    event_hash['columns'] = sprintf_points.keys
    event_hash['points'] = []
    event_hash['points'] << sprintf_points.values
    buffer_receive(event_hash)
  end # def receive

#  def flush; return; end
  def flush(events, teardown=false)
   # Avoid creating a new string for newline every time
    newline = "\n".freeze

    # seen_series stores a list of series and associated columns
    # we've seen for each event
    # so that we can attempt to batch up points for a given series.
    #
    # Columns *MUST* be exactly the same
    seen_series = {}
    event_collection = []

    events.each do |ev|
      begin
        if seen_series.has_key?(ev['name']) and (seen_series[ev['name']] == ev['columns'])
          @logger.info("Existing series data found. Appending points to that series")
          event_collection.select {|h| h['points'] << ev['points'][0] if h['name'] == ev['name']}
        elsif seen_series.has_key?(ev['name']) and (seen_series[ev['name']] != ev['columns'])
          @logger.warn("Series '#{ev['name']}' has been seen but columns are different or in a different order. Adding to batch but not under existing series")
          @logger.warn("Existing series columns were: #{seen_series[ev['name']].join(",")} and event columns were: #{ev['columns'].join(",")}")
          event_collection << ev
        else
          seen_series[ev['name']] = ev['columns']
          event_collection << ev
        end
      rescue
        @logger.info("Error adding event to collection", :exception => e)
        next
      end
    end

    post(event_collection.to_json)
  end # def receive_bulk

  def post(body)
    begin
      @logger.debug("Post body: #{body}")
      response = @agent.post!(@url, :body => body)
    rescue EOFError
      @logger.warn("EOF while writing request or reading response header from InfluxDB",
                   :host => @host, :port => @port)
      return # abort this flush
    end

    # Consume the body for error checking
    # This will also free up the connection for reuse.
    body = ""
    begin
      response.read_body { |chunk| body += chunk }
    rescue EOFError
      @logger.warn("EOF while reading response body from InfluxDB",
                   :host => @host, :port => @port)
      return # abort this flush
    end

    if response.status != 200
      @logger.error("Error writing to InfluxDB",
                    :response => response, :response_body => body,
                    :request_body => @queue.join("\n"))
      return
    end
  end # def post

  private
  def to_epoch(t)
    return t.is_a?(Time) ? t.to_i : Time.parse(t).to_i
  end

  def teardown
    buffer_flush(:final => true)
  end # def teardown
end # class LogStash::Outputs::InfluxDB
