require "logstash/inputs/tcp"
require "logstash/namespace"

# Receive graphite metrics. This plugin understands the text-based graphite
# carbon protocol. Both 'N' and specific-timestamp forms are supported, example:
#
#     mysql.slow_query.count 204 N
#     haproxy.live_backends 7 1364608909
#
# 'N' means 'now' for a timestamp. This plugin also supports having the time
# specified in the metric payload:
#
# For every metric received from a client, a single event will be emitted with
# the metric name as the field (like 'mysql.slow_query.count') and the metric
# value as the field's value.
class LogStash::Inputs::Graphite < LogStash::Inputs::Tcp
  config_name "graphite"
  plugin_status "experimental"

  ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze

  public
  def run(output_queue)
    @queue = output_queue
    super(self)
  end

  # This is a silly hack to make the superclass (Tcp) give us a finished event
  # so that we can parse it accordingly.
  def <<(event)
    name, value, time = event["@message"].split(" ")
    event[name] = value.to_f

    if time != "N"
      t = Time.at(time.to_i).gmtime
      event["@timestamp"] = sprintf(ISO8601_STRFTIME, t.year, t.month, t.day, t.hour,
                                    t.min, t.sec, t.tv_usec, t.utc_offset / 3600)
    end

    @queue  << event
  end
end # class LogStash::Inputs::Graphite
