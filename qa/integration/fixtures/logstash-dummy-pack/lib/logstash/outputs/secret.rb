# encoding: utf-8
require "logstash/outputs/base"

# An secret output that does nothing.
class LogStash::Outputs::Secret < LogStash::Outputs::Base
  config_name "secret"

  public
  def register
  end # def register

  public
  def receive(event)
    return "Event received"
  end # def event
end # class LogStash::Outputs::Secret
