# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# statsd is a network daemon for aggregating statistics, such as counters and timers,
# and shipping over UDP to backend services, such as Graphite or Datadog.
#
# The most basic coverage of this plugin is that the 'namespace', 'sender', and
# 'metric' names are combined into the full metric path like so:
#
#     namespace.sender.metric
#
# The general idea is that you send statsd count or latency data and every few
# seconds it will emit the aggregated values to the backend. Example aggregates are
# average, max, stddev, etc.
#
# You can learn about statsd here:
#
# * <http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/>
# * <https://github.com/etsy/statsd>
#
# A simple example usage of this is to count HTTP hits by response code; to learn
# more about that, check out the [log metrics tutorial](../tutorials/metrics-from-logs)
#
# The default final metric sent to statsd would look like this:
#
#     namespace.sender.metric
#
# With regards to this plugin, the default namespace is "logstash", the default sender
# is the ${host} field, and the metric name depends on what is set as the metric name
# in the increment, decrement, timing, count, set or gauge variable. 
#
class LogStash::Outputs::Statsd < LogStash::Outputs::Base
  ## Regex stolen from statsd code
  RESERVED_CHARACTERS_REGEX = /[\:\|\@]/
  config_name "statsd"
  milestone 2

  # The address of the statsd server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect to on your statsd server.
  config :port, :validate => :number, :default => 8125

  # The statsd namespace to use for this metric.
  config :namespace, :validate => :string, :default => "logstash"

  # The name of the sender. Dots will be replaced with underscores.
  config :sender, :validate => :string, :default => "%{host}"

  # An increment metric. Metric names as array.
  config :increment, :validate => :array, :default => []

  # A decrement metric. Metric names as array.
  config :decrement, :validate => :array, :default => []

  # A timing metric. `metric_name => duration` as hash
  config :timing, :validate => :hash, :default => {}

  # A count metric. `metric_name => count` as hash
  config :count, :validate => :hash, :default => {}

  # A set metric. `metric_name => "string"` to append as hash
  config :set, :validate => :hash, :default => {}

  # A gauge metric. `metric_name => gauge` as hash.
  config :gauge, :validate => :hash, :default => {}
  
  # The sample rate for the metric.
  config :sample_rate, :validate => :number, :default => 1

  # Enable debugging.
  config :debug, :validate => :boolean, :default => false, :deprecated => "This setting was never used by this plugin. It will be removed soon."

  public
  def register
    require "statsd"
    @client = Statsd.new(@host, @port)
  end # def register

  public
  def receive(event)
    return unless output?(event)

    @client.namespace = event.sprintf(@namespace) if not @namespace.empty?
    @logger.debug? and @logger.debug("Original sender: #{@sender}")
    sender = event.sprintf(@sender)
    @logger.debug? and @logger.debug("Munged sender: #{sender}")
    @logger.debug? and @logger.debug("Event: #{event}")
    @increment.each do |metric|
      @client.increment(build_stat(event.sprintf(metric), sender), @sample_rate)
    end
    @decrement.each do |metric|
      @client.decrement(build_stat(event.sprintf(metric), sender), @sample_rate)
    end
    @count.each do |metric, val|
      @client.count(build_stat(event.sprintf(metric), sender),
                    event.sprintf(val).to_f, @sample_rate)
    end
    @timing.each do |metric, val|
      @client.timing(build_stat(event.sprintf(metric), sender),
                     event.sprintf(val).to_f, @sample_rate)
    end
    @set.each do |metric, val|
      @client.set(build_stat(event.sprintf(metric), sender),
                    event.sprintf(val), @sample_rate)
    end
    @gauge.each do |metric, val|
      @client.gauge(build_stat(event.sprintf(metric), sender),
                    event.sprintf(val).to_f, @sample_rate)
    end
  end # def receive

  def build_stat(metric, sender=@sender)
    sender = sender.gsub('::','.').gsub(RESERVED_CHARACTERS_REGEX, '_').gsub(".", "_")
    metric = metric.gsub('::','.').gsub(RESERVED_CHARACTERS_REGEX, '_')
    @logger.debug? and @logger.debug("Formatted value", :sender => sender, :metric => metric)
    return "#{sender}.#{metric}"
  end
end # class LogStash::Outputs::Statsd
