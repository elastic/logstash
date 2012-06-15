require "logstash/outputs/base"
require "logstash/namespace"

# A null output. This is useful for testing logstash inputs and filters for
# performance.
class LogStash::Outputs::Null < LogStash::Outputs::Base
  config_name "null"
  plugin_status "stable"

  public
  def register
    @metric_hits = @logger.metrics.meter(self, "events")
  end # def register

  public
  def receive(event)
    @metric_hits.mark
  end # def event
end # class LogStash::Outputs::Null
