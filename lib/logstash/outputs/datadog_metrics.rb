# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"

# This output lets you send metrics to
# DataDogHQ based on Logstash events.

# Default queue_size and timeframe are low in order to provide near realtime alerting.
# If you do not use Datadog for alerting, consider raising these thresholds.

class LogStash::Outputs::DatadogMetrics < LogStash::Outputs::Base

  include Stud::Buffer

  config_name "datadog_metrics"
  milestone 1

  # Your DatadogHQ API key. https://app.datadoghq.com/account/settings#api
  config :api_key, :validate => :string, :required => true

  # The name of the time series.
  config :metric_name, :validate => :string, :default => "%{metric_name}"

  # The value.
  config :metric_value, :default => "%{metric_value}"

  # The type of the metric.
  config :metric_type, :validate => ["gauge", "counter", "%{metric_type}"], :default => "%{metric_type}"

  # The name of the host that produced the metric.
  config :host, :validate => :string, :default => "%{host}"

  # The name of the device that produced the metric.
  config :device, :validate => :string, :default => "%{metric_device}"

  # Set any custom tags for this event,
  # default are the Logstash tags if any.
  config :dd_tags, :validate => :array

  # How many events to queue before flushing to Datadog
  # prior to schedule set in @timeframe
  config :queue_size, :validate => :number, :default => 10

  # How often (in seconds) to flush queued events to Datadog
  config :timeframe, :validate => :number, :default => 10

  public
  def register
    require 'time'
    require "net/https"
    require "uri"

    @url = "https://app.datadoghq.com/api/v1/series"
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = true
    @client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @logger.debug("Client", :client => @client.inspect)
    buffer_initialize(
      :max_items => @queue_size,
      :max_interval => @timeframe,
      :logger => @logger
    )
  end # def register

  public
  def receive(event)
    return unless output?(event)
    return unless @metric_name && @metric_value && @metric_type
    return unless ["gauge", "counter"].include? event.sprintf(@metric_type)

    dd_metrics = Hash.new
    dd_metrics['metric'] = event.sprintf(@metric_name)
    dd_metrics['points'] = [[to_epoch(event.timestamp), event.sprintf(@metric_value).to_f]]
    dd_metrics['type'] = event.sprintf(@metric_type)
    dd_metrics['host'] = event.sprintf(@host)
    dd_metrics['device'] = event.sprintf(@device)

    if @dd_tags
      tagz = @dd_tags.collect {|x| event.sprintf(x) }
    else
      tagz = event["tags"]
    end
    dd_metrics['tags'] = tagz if tagz

    @logger.info("Queueing event", :event => dd_metrics)
    buffer_receive(dd_metrics)
  end # def receive

  public
  def flush(events, final=false)
    dd_series = Hash.new
    dd_series['series'] = []

    events.each do |event|
      begin
        dd_series['series'] << event
      rescue
        @logger.warn("Error adding event to series!", :exception => e)
        next
      end
    end

    request = Net::HTTP::Post.new("#{@uri.path}?api_key=#{@api_key}")

    begin
      request.body = dd_series.to_json
      request.add_field("Content-Type", 'application/json')
      response = @client.request(request)
      @logger.info("DD convo", :request => request.inspect, :response => response.inspect)
      raise unless response.code == '202'
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request.inspect, :response => response.inspect, :exception => e.inspect)
    end
  end # def flush

  private
  def to_epoch(t)
    return t.is_a?(Time) ? t.to_i : Time.parse(t).to_i
  end # def to_epoch

end # class LogStash::Outputs::DatadogMetrics
