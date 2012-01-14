require "logstash/outputs/base"
require "logstash/namespace"

# A null output. This is useful for testing logstash inputs and filters for
# performance.
class LogStash::Outputs::Null < LogStash::Outputs::Base
  config_name "null"
  plugin_status "stable"

  public
  def register
    # Nothing to do
  end # def register

  public
  def receive(event)
    # Do nothing
  end # def event
end # class LogStash::Outputs::Null
