require "logstash/filters/base"
require "logstash/namespace"

# TODO(sissel): Fill in
class LogStash::Filters::Metrics < LogStash::Filters::Base
  config_name "metrics"
  plugin_status "experimental"

  # syntax: meter => [ "name of metric", "name of metric" ]
  config :meter, :validate => :array, :default => []

  # syntax: timer => [ "name of metric", "%{time_value}" ]
  config :timer, :validate => :hash, :default => {}

  def register
    require "metriks"
    require "socket"
    
    @metric_meters = Hash.new { |h,k| h[k] = Metriks.meter(k) }
    @metric_timers = Hash.new { |h,k| h[k] = Metriks.timer(k) }
  end # def register

  def filter(event)
    return unless filter?(event)

    @meter.each do |m|
      @metric_meters[event.sprintf(m)].mark
    end

    @timer.each do |name, value|
      @metric_timers[event.sprintf(name)].update(event.sprintf(value).to_f)
    end
  end # def filter

  def flush
    event = LogStash::Event.new
    event.source_host = Socket.gethostname
    @metric_meters.each do |name, metric|
      event["#{name}.count"] = metric.count
      event["#{name}.rate_1m"] = metric.one_minute_rate
      event["#{name}.rate_5m"] = metric.five_minute_rate
      event["#{name}.rate_15m"] = metric.fifteen_minute_rate
    end

    @metric_timers.each do |name, metric|
      event["#{name}.count"] = metric.count
      event["#{name}.rate_1m"] = metric.one_minute_rate
      event["#{name}.rate_5m"] = metric.five_minute_rate
      event["#{name}.rate_15m"] = metric.fifteen_minute_rate
      event["#{name}.min"] = metric.min
      event["#{name}.max"] = metric.max
      event["#{name}.stddev"] = metric.stddev
    end

    filter_matched(event)
    return [event]
  end
end # class LogStash::Filter::KV
