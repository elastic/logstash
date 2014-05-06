# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"
require "stud/buffer"

# This output lets you store logs in Keen IO.
#
# You can learn more about Keen IO at <http://keen.io>
class LogStash::Outputs::Keen < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "keen"
  milestone 1

  # The collection to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indices by day so you can more easily
  # delete old data or only search specific date ranges.
  config :collection, :validate => :string, :default => "FUXNE-%{+YYYY.MM.dd}"

  # The Project ID to which you'll be writing.
  config :project_id, :validate => :string, :default => nil

  # The Write Key used to write to your project.
  config :write_key, :validate => :string, :default => nil

  # This plugin uses the bulk index api for improved indexing performance.
  # To make efficient bulk api calls, we will buffer a certain number of
  # events before flushing that out to Keen. This setting
  # controls how many events will be buffered before sending a batch
  # of events.
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
    require "keen" # gem ftw

    @keen = Keen::Client.new(
      :project_id => @project_id,
      :write_key => @write_key
    )
    @queue = []

    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end # def register

  public
  def receive(event)
    return unless output?(event)
    buffer_receive([event])
  end # def receive

  def flush(events, teardown=false)

    # Not sure why this is an array of arrays...
    body = events.flatten(1).collect do |event|
      header = {}
      final = event.to_hash
      final["keen"] = {
        "timestamp" => event["@timestamp"]
      }
      final
    end

    post(body)
  end # def flush

  def post(body)
    @logger.debug("Posting events to Keen IO", :size => body.size
    begin
      @keen.publish_batch(
        @collection => body
      )
    rescue Exception => e
      @logger.warn(e.message)
    end
  end # def post

  def teardown
    buffer_flush(:final => true)
  end # def teardown
end # class LogStash::Outputs::Keen
