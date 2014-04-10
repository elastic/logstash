# encoding: utf-8
require "securerandom"
require "logstash/filters/base"
require "logstash/namespace"

# The metrics filter is useful for aggregating metrics.
#
# For example, if you have a field 'response' that is
# a http response code, and you want to count each
# kind of response, you can do this:
#
#     filter {
#       metrics {
#         meter => [ "http.%{response}" ]
#         add_tag => "metric"
#       }
#     }
#
# Metrics are flushed every 5 seconds by default or according to
# 'flush_interval'. Metrics appear as
# new events in the event stream and go through any filters
# that occur after as well as outputs.
#
# In general, you will want to add a tag to your metrics and have an output
# explicitly look for that tag.
#
# The event that is flushed will include every 'meter' and 'timer'
# metric in the following way:
#
# #### 'meter' values
#
# For a `meter => "something"` you will receive the following fields:
#
# * "thing.count" - the total count of events
# * "thing.rate_1m" - the 1-minute rate (sliding)
# * "thing.rate_5m" - the 5-minute rate (sliding)
# * "thing.rate_15m" - the 15-minute rate (sliding)
#
# #### 'timer' values
#
# For a `timer => [ "thing", "%{duration}" ]` you will receive the following fields:
#
# * "thing.count" - the total count of events
# * "thing.rate_1m" - the 1-minute rate of events (sliding)
# * "thing.rate_5m" - the 5-minute rate of events (sliding)
# * "thing.rate_15m" - the 15-minute rate of events (sliding)
# * "thing.min" - the minimum value seen for this metric
# * "thing.max" - the maximum value seen for this metric
# * "thing.stddev" - the standard deviation for this metric
# * "thing.mean" - the mean for this metric
# * "thing.pXX" - the XXth percentile for this metric (see `percentiles`)
#
# #### Example: computing event rate
#
# For a simple example, let's track how many events per second are running
# through logstash:
#
#     input {
#       generator {
#         type => "generated"
#       }
#     }
#
#     filter {
#       if [type] == "generated" {
#         metrics {
#           meter => "events"
#           add_tag => "metric"
#         }
#       }
#     }
#
#     output {
#       # only emit events with the 'metric' tag
#       if "metric" in [tags] {
#         stdout {
#           message => "rate: %{events.rate_1m}"
#         }
#       }
#     }
#
# Running the above:
#
#     % java -jar logstash.jar agent -f example.conf
#     rate: 23721.983566819246
#     rate: 24811.395722536377
#     rate: 25875.892745934525
#     rate: 26836.42375967113
#
# We see the output includes our 'events' 1-minute rate.
#
# In the real world, you would emit this to graphite or another metrics store,
# like so:
#
#     output {
#       graphite {
#         metrics => [ "events.rate_1m", "%{events.rate_1m}" ]
#       }
#     }
class LogStash::Filters::Metrics < LogStash::Filters::Base
  config_name "metrics"
  milestone 1

  # syntax: `meter => [ "name of metric", "name of metric" ]`
  config :meter, :validate => :array, :default => []

  # syntax: `timer => [ "name of metric", "%{time_value}" ]`
  config :timer, :validate => :hash, :default => {}

  # Don't track events that have @timestamp older than some number of seconds.
  #
  # This is useful if you want to only include events that are near real-time
  # in your metrics.
  #
  # Example, to only count events that are within 10 seconds of real-time, you
  # would do this:
  #
  #     filter {
  #       metrics {
  #         meter => [ "hits" ]
  #         ignore_older_than => 10
  #       }
  #     }
  config :ignore_older_than, :validate => :number, :default => 0

  # The flush interval, when the metrics event is created. Must be a multiple of 5s.
  config :flush_interval, :validate => :number, :default => 5

  # The clear interval, when all counter are reset.
  #
  # If set to -1, the default value, the metrics will never be cleared.
  # Otherwise, should be a multiple of 5s.
  config :clear_interval, :validate => :number, :default => -1

  # The rates that should be measured, in minutes.
  # Possible values are 1, 5, and 15.
  config :rates, :validate => :array, :default => [1, 5, 15]

  # The percentiles that should be measured
  config :percentiles, :validate => :array, :default => [1, 5, 10, 90, 95, 99, 100]

  def register
    require "metriks"
    require "socket"
    require "atomic"
    require "thread_safe"
    @last_flush = Atomic.new(0) # how many seconds ago the metrics where flushed.
    @last_clear = Atomic.new(0) # how many seconds ago the metrics where cleared.
    @random_key_preffix = SecureRandom.hex
    unless (@rates - [1, 5, 15]).empty?
      raise LogStash::ConfigurationError, "Invalid rates configuration. possible rates are 1, 5, 15. Rates: #{rates}."
    end
    @metric_meters = ThreadSafe::Cache.new { |h,k| h[k] = Metriks.meter metric_key(k) }
    @metric_timers = ThreadSafe::Cache.new { |h,k| h[k] = Metriks.timer metric_key(k) }
  end # def register

  def filter(event)
    return unless filter?(event)

    # TODO(piavlo): This should probably be moved to base filter class.
    if @ignore_older_than > 0 && Time.now - event["@timestamp"] > @ignore_older_than
      @logger.debug("Skipping metriks for old event", :event => event)
      return
    end

    @meter.each do |m|
      @metric_meters[event.sprintf(m)].mark
    end

    @timer.each do |name, value|
      @metric_timers[event.sprintf(name)].update(event.sprintf(value).to_f)
    end
  end # def filter

  def flush
    # Add 5 seconds to @last_flush and @last_clear counters
    # since this method is called every 5 seconds.
    @last_flush.update { |v| v + 5 }
    @last_clear.update { |v| v + 5 }

    # Do nothing if there's nothing to do ;)
    return unless should_flush?

    event = LogStash::Event.new
    event["message"] = Socket.gethostname
    @metric_meters.each_pair do |name, metric|
      flush_rates event, name, metric
      metric.clear if should_clear?
    end

    @metric_timers.each_pair do |name, metric|
      flush_rates event, name, metric
      # These 4 values are not sliding, so they probably are not useful.
      event["#{name}.min"] = metric.min
      event["#{name}.max"] = metric.max
      # timer's stddev currently returns variance, fix it.
      event["#{name}.stddev"] = metric.stddev ** 0.5
      event["#{name}.mean"] = metric.mean

      @percentiles.each do |percentile|
        event["#{name}.p#{percentile}"] = metric.snapshot.value(percentile / 100.0)
      end
      metric.clear if should_clear?
    end

    # Reset counter since metrics were flushed
    @last_flush.value = 0

    if should_clear?
      #Reset counter since metrics were cleared
      @last_clear.value = 0
      @metric_meters.clear
      @metric_timers.clear
    end

    filter_matched(event)
    return [event]
  end

  private
  def flush_rates(event, name, metric)
      event["#{name}.count"] = metric.count
      event["#{name}.rate_1m"] = metric.one_minute_rate if @rates.include? 1
      event["#{name}.rate_5m"] = metric.five_minute_rate if @rates.include? 5
      event["#{name}.rate_15m"] = metric.fifteen_minute_rate if @rates.include? 15
  end

  def metric_key(key)
    "#{@random_key_preffix}_#{key}"
  end

  def should_flush?
    @last_flush.value >= @flush_interval && (!@metric_meters.empty? || !@metric_timers.empty?)
  end

  def should_clear?
    @clear_interval > 0 && @last_clear.value >= @clear_interval
  end
end # class LogStash::Filters::Metrics
